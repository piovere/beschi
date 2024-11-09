// This file was automatically generated by Beschi v0.2.0
// <https://github.com/sjml/beschi>
// Do not edit directly.

const std = @import("std");

const DataReaderError = error {
    EOF,
    InvalidData,
};

fn _numberTypeIsValid(comptime T: type) bool {
    const validNumericTypes = [_]type{
        bool,
        u8,  i8,
        u16, i16,
        u32, i32,
        u64, i64,
        f32, f64,
    };
    for (validNumericTypes) |vt| {
        if (T == vt) {
            return true;
        }
    }
    return false;
}

fn _typeIsSimple(comptime T: type) bool {
    if (comptime _numberTypeIsValid(T)) {
        return true;
    }
    const simpleTypes = [_]type{
        Color, Vector3Message,
    };
    for (simpleTypes) |vt| {
        if (T == vt) {
            return true;
        }
    }
    return false;
}

pub fn readNumber(comptime T: type, offset: usize, buffer: []const u8) !struct { value: T, bytes_read: usize } {
    comptime {
        if (!_numberTypeIsValid(T)) {
            @compileError("Invalid number type");
        }
    }

    if (offset + @sizeOf(T) > buffer.len) {
        return DataReaderError.EOF;
    }

    switch (T) {
        f32 => return .{ .value = @bitCast(std.mem.readInt(u32, buffer[offset..][0..@sizeOf(T)], .little)), .bytes_read = @sizeOf(T) },
        f64 => return .{ .value = @bitCast(std.mem.readInt(u64, buffer[offset..][0..@sizeOf(T)], .little)), .bytes_read = @sizeOf(T) },
        bool => return .{ .value = std.mem.readInt(u8, buffer[offset..][0..@sizeOf(T)], .little) != 0, .bytes_read = @sizeOf(T) },
        else => return .{ .value = std.mem.readInt(T, buffer[offset..][0..@sizeOf(T)], .little), .bytes_read = @sizeOf(T) },
    }
}

pub fn readString(allocator: std.mem.Allocator, offset: usize, buffer: []const u8) !struct { value: []u8, bytes_read: usize } {
    const len_read = try readNumber(u8, offset, buffer);
    const len = len_read.value;

    if (offset + @sizeOf(u8) + len > buffer.len) {
        return DataReaderError.EOF;
    }

    var str = try allocator.alloc(u8, len);
    for (0..len) |i| {
        str[i] = buffer[offset + len_read.bytes_read + i];
    }
    return .{ .value = str, .bytes_read = @sizeOf(u8) + len };
}

pub fn readList(comptime T: type, allocator: std.mem.Allocator, offset: usize, buffer: []const u8) !struct { value: []T, bytes_read: usize } {
    var local_offset = offset;
    const len_read = try readNumber(u16, local_offset, buffer);
    const len = len_read.value;
    local_offset += len_read.bytes_read;
    var list = try allocator.alloc(T, len);
    var made_count: u16 = 0;

    errdefer {
        for (0..made_count) |i| {
            if (comptime _numberTypeIsValid(T)) {
                // no-op; just keeping the same structure as below
            }
            else {
                switch (T) {
                    []u8, []const u8 => {
                        allocator.free(list[i]);
                    },
                    else => {
                        if (comptime _typeIsSimple(T)) {
                            // no-op
                        }
                        else {
                            list[i].deinit(allocator);
                        }
                    }
                }
            }
        }
        allocator.free(list);
    }

    for (0..len) |i| {
        if (comptime _numberTypeIsValid(T)) {
            const list_read = try readNumber(T, local_offset, buffer);
            list[i] = list_read.value;
            local_offset += list_read.bytes_read;
        } else {
            switch (T) {
                []u8, []const u8 => {
                    const list_read = try readString(allocator, local_offset, buffer);
                    list[i] = list_read.value;
                    local_offset += list_read.bytes_read;
                },
                else => {
                    if (comptime _typeIsSimple(T)) {
                        const list_read = try T.fromBytes(local_offset, buffer);
                        list[i] = list_read.value;
                        local_offset += list_read.bytes_read;
                    }
                    else {
                        const list_read = try T.fromBytes(allocator, local_offset, buffer);
                        list[i] = list_read.value;
                        local_offset += list_read.bytes_read;
                    }
                },
            }
        }
        made_count += 1;
    }
    return .{ .value = list, .bytes_read = local_offset - offset };
}

pub fn writeNumber(comptime T: type, offset: usize, buffer: []u8, value: T) usize {
    comptime {
        if (!_numberTypeIsValid(T)) {
            @compileError("Invalid number type");
        }
    }

    const slice = buffer[offset..][0..@sizeOf(T)];
    switch (T) {
        f32 => std.mem.writeInt(u32, @constCast(slice), @bitCast(value), .little),
        f64 => std.mem.writeInt(u64, @constCast(slice), @bitCast(value), .little),
        bool => std.mem.writeInt(u8, @constCast(slice), @intFromBool(value), .little),
        else => std.mem.writeInt(T, @constCast(slice), value, .little),
    }
    return @sizeOf(T);
}

pub fn writeString(offset: usize, buffer: []u8, value: []const u8) usize {
    _ = writeNumber(u16, offset, buffer, @intCast(value.len));
    std.mem.copyForwards(u8, buffer[offset+@sizeOf(u16)..][0..value.len], value);
    return @sizeOf(u16) + value.len;
}

pub fn writeList(comptime T: type, offset: usize, buffer: []u8, value: []T) usize {
    var local_offset = offset;
    local_offset += writeNumber(u16, local_offset, buffer, @intCast(value.len));

    for (value) |item| {
        if (comptime _numberTypeIsValid(T)) {
            local_offset += writeNumber(T, local_offset, buffer, item);
        }
        else {
            switch(T) {
                []u8, []const u8 => {
                    local_offset += writeString(local_offset, buffer, item);
                },
                else => {
                    local_offset += item.writeBytes(local_offset, buffer);
                }
            }
        }
    }
    return local_offset - offset;
}

pub fn writeBytes(m: *const Message, offset: usize, buffer: []u8, tag: bool) usize {
    switch (m.*) {
        inline else => |inner| return inner.writeBytes(offset, buffer, tag),
    }
}

pub const MessageType = enum(u8) {
    Vector3Message,
    NewCharacterMessage,
    CharacterJoinedTeam,
};

pub const Message = union(MessageType) {
    Vector3Message: Vector3Message,
    NewCharacterMessage: NewCharacterMessage,
    CharacterJoinedTeam: CharacterJoinedTeam,
};

pub fn processRawBytes(allocator: std.mem.Allocator, buffer: []const u8) ![]Message {
    var msg_list = std.ArrayList(Message).init(allocator);
    defer msg_list.deinit();

    var local_offset: usize = 0;
    while (local_offset < buffer.len) {
        const msg_type_byte = (try readNumber(u8, local_offset, buffer)).value;
        local_offset += 1;
        if (msg_type_byte == 0) {
            return msg_list.toOwnedSlice();
        }
        const msg_type: MessageType = std.meta.intToEnum(MessageType, msg_type_byte - 1) catch return DataReaderError.InvalidData;
        switch(msg_type) {
            .Vector3Message => {
                const msg_read = try Vector3Message.fromBytes(local_offset, buffer);
                local_offset += msg_read.bytes_read;
                try msg_list.append(Message{ .Vector3Message = msg_read.value });
            },
            .NewCharacterMessage => {
                const msg_read = try NewCharacterMessage.fromBytes(allocator, local_offset, buffer);
                local_offset += msg_read.bytes_read;
                try msg_list.append(Message{ .NewCharacterMessage = msg_read.value });
            },
            .CharacterJoinedTeam => {
                const msg_read = try CharacterJoinedTeam.fromBytes(allocator, local_offset, buffer);
                local_offset += msg_read.bytes_read;
                try msg_list.append(Message{ .CharacterJoinedTeam = msg_read.value });
            },
        }
    }
    return msg_list.toOwnedSlice();
}

pub const CharacterClass = enum(u8) {
    Fighter = 0,
    Wizard = 1,
    Rogue = 2,
    Cleric = 3,
};

pub const TeamRole = enum(u8) {
    Minion = 0,
    Ally = 1,
    Leader = 2,
};

pub const Color = struct {
    red: f32 = 0.0,
    green: f32 = 0.0,
    blue: f32 = 0.0,
    alpha: f32 = 0.0,

    pub fn getSizeInBytes(self: *const Color) usize {
        _ = self;
        return 16;
    }

    pub fn fromBytes(offset: usize, buffer: []const u8) !struct { value: Color, bytes_read: usize } {
        const Color_red = (try readNumber(f32, offset + 0, buffer)).value;
        const Color_green = (try readNumber(f32, offset + 4, buffer)).value;
        const Color_blue = (try readNumber(f32, offset + 8, buffer)).value;
        const Color_alpha = (try readNumber(f32, offset + 12, buffer)).value;
        return .{ .value = Color{
            .red = Color_red,
            .green = Color_green,
            .blue = Color_blue,
            .alpha = Color_alpha,
        }, .bytes_read = 16 };
    }

    pub fn writeBytes(self: *const Color, offset: usize, buffer: []u8) usize {
        _ = writeNumber(f32, offset + 0, buffer, self.red);
        _ = writeNumber(f32, offset + 4, buffer, self.green);
        _ = writeNumber(f32, offset + 8, buffer, self.blue);
        _ = writeNumber(f32, offset + 12, buffer, self.alpha);
        return 16;
    }
};

pub const Spectrum = struct {
    defaultColor: Color = Color{},
    colors: []Color = &.{},

    pub fn getSizeInBytes(self: *const Spectrum) usize {
        var size: usize = 0;
        size += self.colors.len * 16;
        size += 18;
        return size;
    }

    pub fn fromBytes(allocator: std.mem.Allocator, offset: usize, buffer: []const u8) !struct { value: Spectrum, bytes_read: usize } {
        var local_offset = offset;

        const Spectrum_defaultColor_read = try Color.fromBytes(local_offset, buffer);
        const Spectrum_defaultColor = Spectrum_defaultColor_read.value;
        local_offset += Spectrum_defaultColor_read.bytes_read;

        const Spectrum_colors_read = try readList(Color, allocator, local_offset, buffer);
        const Spectrum_colors = Spectrum_colors_read.value;
        local_offset += Spectrum_colors_read.bytes_read;

        return .{ .value = Spectrum{
            .defaultColor = Spectrum_defaultColor,
            .colors = Spectrum_colors,
        }, .bytes_read = local_offset - offset };
    }

    pub fn writeBytes(self: *const Spectrum, offset: usize, buffer: []u8) usize {
        var local_offset = offset;

        local_offset += self.defaultColor.writeBytes(local_offset, buffer);
        local_offset += writeList(Color, local_offset, buffer, self.colors);

        return local_offset - offset;
    }

    pub fn deinit(self: *Spectrum, allocator: std.mem.Allocator) void {
        allocator.free(self.colors);
    }
};

pub const Vector3Message = struct {
    x: f32 = 0.0,
    y: f32 = 0.0,
    z: f32 = 0.0,

    pub fn getSizeInBytes(self: *const Vector3Message) usize {
        _ = self;
        return 12;
    }

    pub fn fromBytes(offset: usize, buffer: []const u8) !struct { value: Vector3Message, bytes_read: usize } {
        const Vector3Message_x = (try readNumber(f32, offset + 0, buffer)).value;
        const Vector3Message_y = (try readNumber(f32, offset + 4, buffer)).value;
        const Vector3Message_z = (try readNumber(f32, offset + 8, buffer)).value;
        return .{ .value = Vector3Message{
            .x = Vector3Message_x,
            .y = Vector3Message_y,
            .z = Vector3Message_z,
        }, .bytes_read = 12 };
    }

    pub fn writeBytes(self: *const Vector3Message, offset: usize, buffer: []u8, tag: bool) usize {
        var local_offset = offset;

        if (tag) {
            local_offset += writeNumber(u8, local_offset, buffer, 1);
        }
        local_offset += writeNumber(f32, local_offset, buffer, self.x);
        local_offset += writeNumber(f32, local_offset, buffer, self.y);
        local_offset += writeNumber(f32, local_offset, buffer, self.z);

        return local_offset - offset;
    }
};

pub const NewCharacterMessage = struct {
    id: u64 = 0,
    characterName: []const u8 = "",
    job: CharacterClass = CharacterClass.Fighter,
    strength: u16 = 0,
    intelligence: u16 = 0,
    dexterity: u16 = 0,
    wisdom: u16 = 0,
    goldInWallet: u32 = 0,
    nicknames: [][]const u8 = &.{},

    pub fn getSizeInBytes(self: *const NewCharacterMessage) usize {
        var size: usize = 0;
        size += self.characterName.len;
        for (self.nicknames) |s| {
            size += 1 + s.len;
        }
        size += 24;
        return size;
    }

    pub fn fromBytes(allocator: std.mem.Allocator, offset: usize, buffer: []const u8) !struct { value: NewCharacterMessage, bytes_read: usize } {
        var local_offset = offset;

        const NewCharacterMessage_id_read = try readNumber(u64, local_offset, buffer);
        const NewCharacterMessage_id = NewCharacterMessage_id_read.value;
        local_offset += NewCharacterMessage_id_read.bytes_read;

        const NewCharacterMessage_characterName_read = try readString(allocator, local_offset, buffer);
        const NewCharacterMessage_characterName = NewCharacterMessage_characterName_read.value;
        local_offset += NewCharacterMessage_characterName_read.bytes_read;

        const NewCharacterMessage_job_check_read = try readNumber(u8, local_offset, buffer);
        // TODO: check for validity of integer; not implemented for now since going to add non-sequentiality first
        const NewCharacterMessage_job: CharacterClass = @enumFromInt(NewCharacterMessage_job_check_read.value);
        local_offset += NewCharacterMessage_job_check_read.bytes_read;

        const NewCharacterMessage_strength_read = try readNumber(u16, local_offset, buffer);
        const NewCharacterMessage_strength = NewCharacterMessage_strength_read.value;
        local_offset += NewCharacterMessage_strength_read.bytes_read;

        const NewCharacterMessage_intelligence_read = try readNumber(u16, local_offset, buffer);
        const NewCharacterMessage_intelligence = NewCharacterMessage_intelligence_read.value;
        local_offset += NewCharacterMessage_intelligence_read.bytes_read;

        const NewCharacterMessage_dexterity_read = try readNumber(u16, local_offset, buffer);
        const NewCharacterMessage_dexterity = NewCharacterMessage_dexterity_read.value;
        local_offset += NewCharacterMessage_dexterity_read.bytes_read;

        const NewCharacterMessage_wisdom_read = try readNumber(u16, local_offset, buffer);
        const NewCharacterMessage_wisdom = NewCharacterMessage_wisdom_read.value;
        local_offset += NewCharacterMessage_wisdom_read.bytes_read;

        const NewCharacterMessage_goldInWallet_read = try readNumber(u32, local_offset, buffer);
        const NewCharacterMessage_goldInWallet = NewCharacterMessage_goldInWallet_read.value;
        local_offset += NewCharacterMessage_goldInWallet_read.bytes_read;

        const NewCharacterMessage_nicknames_read = try readList([]const u8, allocator, local_offset, buffer);
        const NewCharacterMessage_nicknames = NewCharacterMessage_nicknames_read.value;
        local_offset += NewCharacterMessage_nicknames_read.bytes_read;

        return .{ .value = NewCharacterMessage{
            .id = NewCharacterMessage_id,
            .characterName = NewCharacterMessage_characterName,
            .job = NewCharacterMessage_job,
            .strength = NewCharacterMessage_strength,
            .intelligence = NewCharacterMessage_intelligence,
            .dexterity = NewCharacterMessage_dexterity,
            .wisdom = NewCharacterMessage_wisdom,
            .goldInWallet = NewCharacterMessage_goldInWallet,
            .nicknames = NewCharacterMessage_nicknames,
        }, .bytes_read = local_offset - offset };
    }

    pub fn writeBytes(self: *const NewCharacterMessage, offset: usize, buffer: []u8, tag: bool) usize {
        var local_offset = offset;
        if (tag) {
            local_offset += writeNumber(u8, local_offset, buffer, 2);
        }

        local_offset += writeNumber(u64, local_offset, buffer, self.id);
        local_offset += writeString(local_offset, buffer, self.characterName);
        local_offset += writeNumber(u8, local_offset, buffer, @intFromEnum(self.job));
        local_offset += writeNumber(u16, local_offset, buffer, self.strength);
        local_offset += writeNumber(u16, local_offset, buffer, self.intelligence);
        local_offset += writeNumber(u16, local_offset, buffer, self.dexterity);
        local_offset += writeNumber(u16, local_offset, buffer, self.wisdom);
        local_offset += writeNumber(u32, local_offset, buffer, self.goldInWallet);
        local_offset += writeList([]const u8, local_offset, buffer, self.nicknames);

        return local_offset - offset;
    }

    pub fn deinit(self: *NewCharacterMessage, allocator: std.mem.Allocator) void {
        allocator.free(self.characterName);
        for (self.nicknames) |item2| {
            allocator.free(item2);
        }
        allocator.free(self.nicknames);
    }
};

pub const CharacterJoinedTeam = struct {
    characterID: u64 = 0,
    teamName: []const u8 = "",
    teamColors: []Color = &.{},
    role: TeamRole = TeamRole.Minion,

    pub fn getSizeInBytes(self: *const CharacterJoinedTeam) usize {
        var size: usize = 0;
        size += self.teamName.len;
        size += self.teamColors.len * 16;
        size += 12;
        return size;
    }

    pub fn fromBytes(allocator: std.mem.Allocator, offset: usize, buffer: []const u8) !struct { value: CharacterJoinedTeam, bytes_read: usize } {
        var local_offset = offset;

        const CharacterJoinedTeam_characterID_read = try readNumber(u64, local_offset, buffer);
        const CharacterJoinedTeam_characterID = CharacterJoinedTeam_characterID_read.value;
        local_offset += CharacterJoinedTeam_characterID_read.bytes_read;

        const CharacterJoinedTeam_teamName_read = try readString(allocator, local_offset, buffer);
        const CharacterJoinedTeam_teamName = CharacterJoinedTeam_teamName_read.value;
        local_offset += CharacterJoinedTeam_teamName_read.bytes_read;

        const CharacterJoinedTeam_teamColors_read = try readList(Color, allocator, local_offset, buffer);
        const CharacterJoinedTeam_teamColors = CharacterJoinedTeam_teamColors_read.value;
        local_offset += CharacterJoinedTeam_teamColors_read.bytes_read;

        const CharacterJoinedTeam_role_check_read = try readNumber(u8, local_offset, buffer);
        // TODO: check for validity of integer; not implemented for now since going to add non-sequentiality first
        const CharacterJoinedTeam_role: TeamRole = @enumFromInt(CharacterJoinedTeam_role_check_read.value);
        local_offset += CharacterJoinedTeam_role_check_read.bytes_read;

        return .{ .value = CharacterJoinedTeam{
            .characterID = CharacterJoinedTeam_characterID,
            .teamName = CharacterJoinedTeam_teamName,
            .teamColors = CharacterJoinedTeam_teamColors,
            .role = CharacterJoinedTeam_role,
        }, .bytes_read = local_offset - offset };
    }

    pub fn writeBytes(self: *const CharacterJoinedTeam, offset: usize, buffer: []u8, tag: bool) usize {
        var local_offset = offset;
        if (tag) {
            local_offset += writeNumber(u8, local_offset, buffer, 3);
        }

        local_offset += writeNumber(u64, local_offset, buffer, self.characterID);
        local_offset += writeString(local_offset, buffer, self.teamName);
        local_offset += writeList(Color, local_offset, buffer, self.teamColors);
        local_offset += writeNumber(u8, local_offset, buffer, @intFromEnum(self.role));

        return local_offset - offset;
    }

    pub fn deinit(self: *CharacterJoinedTeam, allocator: std.mem.Allocator) void {
        allocator.free(self.teamName);
        allocator.free(self.teamColors);
    }
};

