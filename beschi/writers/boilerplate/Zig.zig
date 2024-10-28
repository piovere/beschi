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

pub fn readNumber(comptime T: type, offset: usize, buffer: []u8) struct { value: T, bytes_read: usize } {
    comptime {
        if (!_numberTypeIsValid(T)) {
            @compileError("Invalid number type");
        }
    }

    switch (T) {
        f32 => return .{ .value = @bitCast(std.mem.readInt(u32, buffer[offset..][0..@sizeOf(T)], .little)), .bytes_read = @sizeOf(T) },
        f64 => return .{ .value = @bitCast(std.mem.readInt(u64, buffer[offset..][0..@sizeOf(T)], .little)), .bytes_read = @sizeOf(T) },
        bool => return .{ .value = std.mem.readInt(u8, buffer[offset..][0..@sizeOf(T)], .little) != 0, .bytes_read = @sizeOf(T) },
        else => return .{ .value = std.mem.readInt(T, buffer[offset..][0..@sizeOf(T)], .little), .bytes_read = @sizeOf(T) },
    }
}

pub fn readString(allocator: std.mem.Allocator, offset: usize, buffer: []u8) !struct { value: []u8, bytes_read: usize } {
    const len_read = readNumber({# STRING_SIZE_TYPE #}, offset, buffer);
    const len = len_read.value;
    var str = try allocator.alloc(u8, len);
    for (0..len) |i| {
        str[i] = buffer[offset + len_read.bytes_read + i];
    }
    return .{ .value = str, .bytes_read = @sizeOf({# STRING_SIZE_TYPE #}) + len };
}

pub fn readList(comptime T: type, allocator: std.mem.Allocator, offset: usize, buffer: []u8) !struct { value: []T, bytes_read: usize } {
    var local_offset = offset;
    const len_read = readNumber({# LIST_SIZE_TYPE #}, local_offset, buffer);
    const len = len_read.value;
    local_offset += len_read.bytes_read;
    var list = try allocator.alloc(T, len);

    for (0..len) |i| {
        if (comptime _numberTypeIsValid(T)) {
            const list_read = readNumber(T, local_offset, buffer);
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
    _ = writeNumber({# LIST_SIZE_TYPE #}, offset, buffer, @intCast(value.len));
    std.mem.copyForwards(u8, buffer[offset+@sizeOf({# LIST_SIZE_TYPE #})..][0..value.len], value);
    return @sizeOf({# LIST_SIZE_TYPE #}) + value.len;
}

pub fn writeList(comptime T: type, offset: usize, buffer: []u8, value: []T) usize {
    var local_offset = offset;
    local_offset += writeNumber({# LIST_SIZE_TYPE #}, local_offset, buffer, @intCast(value.len));

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