// This file was automatically generated by Beschi v0.2.0
// <https://github.com/sjml/beschi>
// Do not edit directly.

import Foundation

public protocol AppMessages_Message {
    func GetMessageType() -> AppMessages.MessageType
    func WriteBytes(data: inout Data, tag: Bool) -> Void
    func GetSizeInBytes() -> UInt32
}

public /* namespace */ enum AppMessages {
    public enum DataReaderError: Error {
        case EOF
        case InvalidData
    }

    class DataReader {
        let data: Data
        var currentOffset: Int = 0
        init(fromData data: Data) {
            self.data = data
        }

        func IsFinished() -> Bool {
            return self.currentOffset >= self.data.count
        }

        func GetUInt8() throws -> UInt8 {
            if (self.data.count < self.currentOffset + 1) {
                throw DataReaderError.EOF
            }
            let ret = UInt8(littleEndian: data.withUnsafeBytes { dataBytes in
                var val: UInt8 = 0
                memcpy(&val, dataBytes.baseAddress! + self.currentOffset, 1)
                return val
            })
            self.currentOffset += 1
            return ret
        }

        func GetBool() throws -> Bool {
            return try self.GetUInt8() > 0
        }

        func GetInt16() throws -> Int16 {
            if (self.data.count < self.currentOffset + 2) {
                throw DataReaderError.EOF
            }
            let ret = Int16(littleEndian: data.withUnsafeBytes { dataBytes in
                var val: Int16 = 0
                memcpy(&val, dataBytes.baseAddress! + self.currentOffset, 2)
                return val
            })
            self.currentOffset += 2
            return ret
        }

        func GetUInt16() throws -> UInt16 {
            if (self.data.count < self.currentOffset + 2) {
                throw DataReaderError.EOF
            }
            let ret = UInt16(littleEndian: data.withUnsafeBytes { dataBytes in
                var val: UInt16 = 0
                memcpy(&val, dataBytes.baseAddress! + self.currentOffset, 2)
                return val
            })
            self.currentOffset += 2
            return ret
        }

        func GetInt32() throws -> Int32 {
            if (self.data.count < self.currentOffset + 4) {
                throw DataReaderError.EOF
            }
            let ret = Int32(littleEndian: data.withUnsafeBytes { dataBytes in
                var val: Int32 = 0
                memcpy(&val, dataBytes.baseAddress! + self.currentOffset, 4)
                return val
            })
            self.currentOffset += 4
            return ret
        }

        func GetUInt32() throws -> UInt32 {
            if (self.data.count < self.currentOffset + 4) {
                throw DataReaderError.EOF
            }
            let ret = UInt32(littleEndian: data.withUnsafeBytes { dataBytes in
                var val: UInt32 = 0
                memcpy(&val, dataBytes.baseAddress! + self.currentOffset, 4)
                return val
            })
            self.currentOffset += 4
            return ret
        }

        func GetInt64() throws -> Int64 {
            if (self.data.count < self.currentOffset + 8) {
                throw DataReaderError.EOF
            }
            let ret = Int64(littleEndian: data.withUnsafeBytes { dataBytes in
                var val: Int64 = 0
                memcpy(&val, dataBytes.baseAddress! + self.currentOffset, 8)
                return val
            })
            self.currentOffset += 8
            return ret
        }

        func GetUInt64() throws -> UInt64 {
            if (self.data.count < self.currentOffset + 8) {
                throw DataReaderError.EOF
            }
            let ret = UInt64(littleEndian: data.withUnsafeBytes { dataBytes in
                var val: UInt64 = 0
                memcpy(&val, dataBytes.baseAddress! + self.currentOffset, 8)
                return val
            })
            self.currentOffset += 8
            return ret
        }

        func GetFloat32() throws -> Float32 {
            if (self.data.count < self.currentOffset + 4) {
                throw DataReaderError.EOF
            }
            let ret = Float32(bitPattern: UInt32(littleEndian: data.withUnsafeBytes { dataBytes in
                var val: UInt32 = 0
                memcpy(&val, dataBytes.baseAddress! + self.currentOffset, 4)
                return val
            }))
            self.currentOffset += 4
            return ret
        }

        func GetFloat64() throws -> Float64 {
            if (self.data.count < self.currentOffset + 8) {
                throw DataReaderError.EOF
            }
            let ret = Float64(bitPattern: UInt64(littleEndian: data.withUnsafeBytes { dataBytes in
                var val: UInt64 = 0
                memcpy(&val, dataBytes.baseAddress! + self.currentOffset, 8)
                return val
            }))
            self.currentOffset += 8
            return ret
        }

        func GetString() throws -> String {
            let stringLength = try Int(self.GetUInt8())
            if (self.data.count < self.currentOffset + stringLength) {
                throw DataReaderError.EOF
            }
            let stringData = self.data[self.currentOffset..<(self.currentOffset+stringLength)]
            guard
                let ret = String(data: stringData, encoding: String.Encoding.utf8)
            else {
                throw DataReaderError.InvalidData
            }
            self.currentOffset += stringLength
            return ret
        }
    }

    class DataWriter {
        var data: Data
        init() {
            self.data = Data()
        }
        init(withData: inout Data) {
            self.data = withData
        }

        func WriteUInt8(_ ui8: UInt8) {
            self.data.append(ui8)
        }

        func WriteBool(_ b: Bool) {
            self.WriteUInt8(b ? 1 : 0)
        }

        func WriteInt16(_ i16: Int16) {
            var _i16 = Int16(littleEndian: i16)
            self.data.append(withUnsafeBytes(of: &_i16, {Data($0)}))
        }

        func WriteUInt16(_ ui16: UInt16) {
            var _ui16 = UInt16(littleEndian: ui16)
            self.data.append(withUnsafeBytes(of: &_ui16, {Data($0)}))
        }

        func WriteInt32(_ i32: Int32) {
            var _i32 = Int32(littleEndian: i32)
            self.data.append(withUnsafeBytes(of: &_i32, {Data($0)}))
        }

        func WriteUInt32(_ ui32: UInt32) {
            var _ui32 = UInt32(littleEndian: ui32)
            self.data.append(withUnsafeBytes(of: &_ui32, {Data($0)}))
        }

        func WriteInt64(_ i64: Int64) {
            var _i64 = Int64(littleEndian: i64)
            self.data.append(withUnsafeBytes(of: &_i64, {Data($0)}))
        }

        func WriteUInt64(_ ui64: UInt64) {
            var _ui64 = UInt64(littleEndian: ui64)
            self.data.append(withUnsafeBytes(of: &_ui64, {Data($0)}))
        }

        func WriteFloat32(_ f: Float32) {
            var _f = f
            var out = UInt32(littleEndian: withUnsafeBytes(of: &_f, {$0.load(fromByteOffset: 0, as: UInt32.self)}))
            self.data.append(withUnsafeBytes(of: &out, {Data($0)}))
        }

        func WriteFloat64(_ d: Float64) {
            var _d = d
            var out = UInt64(littleEndian: withUnsafeBytes(of: &_d, {$0.load(fromByteOffset: 0, as: UInt64.self)}))
            self.data.append(withUnsafeBytes(of: &out, {Data($0)}))
        }

        func WriteString(_ s: String) {
            let buffer = s.data(using: String.Encoding.utf8)!
            self.WriteUInt8(UInt8(buffer.count))
            self.data.append(buffer)
        }
    }

    public enum MessageType: UInt8 {
        case Vector3MessageType = 1
        case NewCharacterMessageType = 2
        case CharacterJoinedTeamType = 3
    }

    public static func ProcessRawBytes(_ data: Data) throws -> [AppMessages_Message] {
        var msgList: [AppMessages_Message] = []
        let dr = DataReader(fromData: data)
        while !dr.IsFinished() {
            let msgTypeByte = try dr.GetUInt8()
            if msgTypeByte == 0 {
                return msgList
            }
            guard let msgType = AppMessages.MessageType(rawValue: msgTypeByte)
            else {
                throw DataReaderError.InvalidData
            }
            switch msgType {
                case AppMessages.MessageType.Vector3MessageType:
                    msgList.append(try Vector3Message.FromBytes(dataReader: dr))
                case AppMessages.MessageType.NewCharacterMessageType:
                    msgList.append(try NewCharacterMessage.FromBytes(dataReader: dr))
                case AppMessages.MessageType.CharacterJoinedTeamType:
                    msgList.append(try CharacterJoinedTeam.FromBytes(dataReader: dr))
            }
        }
        return msgList
    }

    public enum CharacterClass: UInt8 {
        case Fighter = 0
        case Wizard = 1
        case Rogue = 2
        case Cleric = 3
    }

    public enum TeamRole: Int16 {
        case Minion = 256
        case Ally = 512
        case Leader = 1024
        case Traitor = -1
    }

    public struct Color {
        public var red: Float32 = 0.0
        public var green: Float32 = 0.0
        public var blue: Float32 = 0.0
        public var alpha: Float32 = 0.0

        public init() {}

        static func FromBytes(dataReader: DataReader) throws -> Color {
            var nColor = Color()
            nColor.red = try dataReader.GetFloat32()
            nColor.green = try dataReader.GetFloat32()
            nColor.blue = try dataReader.GetFloat32()
            nColor.alpha = try dataReader.GetFloat32()
            return nColor
        }

        func WriteBytes(_ dataWriter: DataWriter) -> Void {
            dataWriter.WriteFloat32(self.red)
            dataWriter.WriteFloat32(self.green)
            dataWriter.WriteFloat32(self.blue)
            dataWriter.WriteFloat32(self.alpha)
        }
    }

    public struct Spectrum {
        public var defaultColor: Color = Color()
        public var colors: [Color] = []

        public init() {}

        static func FromBytes(dataReader: DataReader) throws -> Spectrum {
            var nSpectrum = Spectrum()
            nSpectrum.defaultColor = try Color.FromBytes(dataReader: dataReader)
            let colors_Length = try dataReader.GetUInt16()
            nSpectrum.colors = []
            for _ in 0..<colors_Length {
                let _colors_el = try Color.FromBytes(dataReader: dataReader)
                nSpectrum.colors.append(_colors_el)
            }
            return nSpectrum
        }

        func WriteBytes(_ dataWriter: DataWriter) -> Void {
            self.defaultColor.WriteBytes(dataWriter)
            dataWriter.WriteUInt16(UInt16(self.colors.count))
            for el in self.colors {
                el.WriteBytes(dataWriter)
            }
        }
    }

    public struct Vector3Message : AppMessages_Message {
        public var x: Float32 = 0.0
        public var y: Float32 = 0.0
        public var z: Float32 = 0.0

        public init() {}

        public func GetMessageType() -> MessageType {
            return MessageType.Vector3MessageType
        }

        public func GetSizeInBytes() -> UInt32 {
            return 12;
        }

        public static func FromBytes(_ fromData: Data) throws -> Vector3Message {
            let dr = DataReader(fromData: fromData)
            return try FromBytes(dataReader: dr)
        }

        static func FromBytes(dataReader: DataReader) throws -> Vector3Message {
            var nVector3Message = Vector3Message()
            nVector3Message.x = try dataReader.GetFloat32()
            nVector3Message.y = try dataReader.GetFloat32()
            nVector3Message.z = try dataReader.GetFloat32()
            return nVector3Message
        }

        public func WriteBytes(data: inout Data, tag: Bool) -> Void {
            let dataWriter = DataWriter(withData: &data)
            if (tag) {
                dataWriter.WriteUInt8(MessageType.Vector3MessageType.rawValue)
            }
            dataWriter.WriteFloat32(self.x)
            dataWriter.WriteFloat32(self.y)
            dataWriter.WriteFloat32(self.z)

            data = dataWriter.data
        }
    }

    public struct NewCharacterMessage : AppMessages_Message {
        public var id: UInt64 = 0
        public var characterName: String = ""
        public var job: CharacterClass = CharacterClass.Fighter
        public var strength: UInt16 = 0
        public var intelligence: UInt16 = 0
        public var dexterity: UInt16 = 0
        public var wisdom: UInt16 = 0
        public var goldInWallet: UInt32 = 0
        public var nicknames: [String] = []

        public init() {}

        public func GetMessageType() -> MessageType {
            return MessageType.NewCharacterMessageType
        }

        public func GetSizeInBytes() -> UInt32 {
            var size = 0
            size += self.characterName.data(using: String.Encoding.utf8)!.count
            for s in self.nicknames {
                size += 1 + s.data(using: String.Encoding.utf8)!.count
            }
            size += 24;
            return UInt32(size)
        }

        public static func FromBytes(_ fromData: Data) throws -> NewCharacterMessage {
            let dr = DataReader(fromData: fromData)
            return try FromBytes(dataReader: dr)
        }

        static func FromBytes(dataReader: DataReader) throws -> NewCharacterMessage {
            var nNewCharacterMessage = NewCharacterMessage()
            nNewCharacterMessage.id = try dataReader.GetUInt64()
            nNewCharacterMessage.characterName = try dataReader.GetString()
            let _jobRead = try dataReader.GetUInt8()
            guard let _job = CharacterClass(rawValue: _jobRead) else {
                throw DataReaderError.InvalidData
            }
            nNewCharacterMessage.job = _job
            nNewCharacterMessage.strength = try dataReader.GetUInt16()
            nNewCharacterMessage.intelligence = try dataReader.GetUInt16()
            nNewCharacterMessage.dexterity = try dataReader.GetUInt16()
            nNewCharacterMessage.wisdom = try dataReader.GetUInt16()
            nNewCharacterMessage.goldInWallet = try dataReader.GetUInt32()
            let nicknames_Length = try dataReader.GetUInt16()
            nNewCharacterMessage.nicknames = []
            for _ in 0..<nicknames_Length {
                let _nicknames_el = try dataReader.GetString()
                nNewCharacterMessage.nicknames.append(_nicknames_el)
            }
            return nNewCharacterMessage
        }

        public func WriteBytes(data: inout Data, tag: Bool) -> Void {
            let dataWriter = DataWriter(withData: &data)
            if (tag) {
                dataWriter.WriteUInt8(MessageType.NewCharacterMessageType.rawValue)
            }
            dataWriter.WriteUInt64(self.id)
            dataWriter.WriteString(self.characterName)
            dataWriter.WriteUInt8(self.job.rawValue)
            dataWriter.WriteUInt16(self.strength)
            dataWriter.WriteUInt16(self.intelligence)
            dataWriter.WriteUInt16(self.dexterity)
            dataWriter.WriteUInt16(self.wisdom)
            dataWriter.WriteUInt32(self.goldInWallet)
            dataWriter.WriteUInt16(UInt16(self.nicknames.count))
            for el in self.nicknames {
                dataWriter.WriteString(el)
            }

            data = dataWriter.data
        }
    }

    public struct CharacterJoinedTeam : AppMessages_Message {
        public var characterID: UInt64 = 0
        public var teamName: String = ""
        public var teamColors: [Color] = []
        public var role: TeamRole = TeamRole.Minion

        public init() {}

        public func GetMessageType() -> MessageType {
            return MessageType.CharacterJoinedTeamType
        }

        public func GetSizeInBytes() -> UInt32 {
            var size = 0
            size += self.teamName.data(using: String.Encoding.utf8)!.count
            size += self.teamColors.count * 16
            size += 13;
            return UInt32(size)
        }

        public static func FromBytes(_ fromData: Data) throws -> CharacterJoinedTeam {
            let dr = DataReader(fromData: fromData)
            return try FromBytes(dataReader: dr)
        }

        static func FromBytes(dataReader: DataReader) throws -> CharacterJoinedTeam {
            var nCharacterJoinedTeam = CharacterJoinedTeam()
            nCharacterJoinedTeam.characterID = try dataReader.GetUInt64()
            nCharacterJoinedTeam.teamName = try dataReader.GetString()
            let teamColors_Length = try dataReader.GetUInt16()
            nCharacterJoinedTeam.teamColors = []
            for _ in 0..<teamColors_Length {
                let _teamColors_el = try Color.FromBytes(dataReader: dataReader)
                nCharacterJoinedTeam.teamColors.append(_teamColors_el)
            }
            let _roleRead = try dataReader.GetInt16()
            guard let _role = TeamRole(rawValue: _roleRead) else {
                throw DataReaderError.InvalidData
            }
            nCharacterJoinedTeam.role = _role
            return nCharacterJoinedTeam
        }

        public func WriteBytes(data: inout Data, tag: Bool) -> Void {
            let dataWriter = DataWriter(withData: &data)
            if (tag) {
                dataWriter.WriteUInt8(MessageType.CharacterJoinedTeamType.rawValue)
            }
            dataWriter.WriteUInt64(self.characterID)
            dataWriter.WriteString(self.teamName)
            dataWriter.WriteUInt16(UInt16(self.teamColors.count))
            for el in self.teamColors {
                el.WriteBytes(dataWriter)
            }
            dataWriter.WriteInt16(self.role.rawValue)

            data = dataWriter.data
        }
    }

}
