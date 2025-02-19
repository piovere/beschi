import Foundation

import GeneratedMessages

var OK: Bool = true
func softAssert(_ condition: Bool, _ label: String) {
    if (!condition) {
        "FAILED! Swift: \(label)\n".data(using: .utf8).map(FileHandle.standardError.write)
        OK = false
    }
}

var parsed: [String: String] = [:]
var currentKeyword: String? = nil
for arg in CommandLine.arguments[1...] {
    if arg.starts(with: "--") {
        currentKeyword = String(arg[arg.index(arg.startIndex, offsetBy: 2)...])
        continue
    }
    if (currentKeyword != nil) {
        parsed[currentKeyword!] = arg
        currentKeyword = nil
        continue
    }
    parsed[arg] = ""
}


let msgList: [SmallMessages.Message] = [
    SmallMessages.IntMessage(),
    SmallMessages.FloatMessage(),
    SmallMessages.FloatMessage(),
    SmallMessages.FloatMessage(),
    SmallMessages.IntMessage(),
    SmallMessages.EmptyMessage(),
    SmallMessages.LongMessage(),
    SmallMessages.LongMessage(),
    SmallMessages.LongMessage(),
    SmallMessages.IntMessage(),
]



if parsed["generate"] != nil {
    let outPath = URL(fileURLWithPath: parsed["generate"]!)
    let outDir = outPath.deletingLastPathComponent()
    try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

    let data = NSMutableData()
    msgList.PackMessages(data)

    try data.write(to: outPath)

    softAssert(data.count == 67, "written bytes check")
}
else if parsed["read"] != nil {
    let data = try Data(contentsOf: URL(fileURLWithPath: parsed["read"]!))

    let msgList = try SmallMessages.Message.UnpackMessages(data)

    softAssert(msgList.count == 10, "packed count")

    softAssert(msgList[0].GetMessageType() == SmallMessages.MessageType.IntMessageType, "packed[0]")
    softAssert(msgList[1].GetMessageType() == SmallMessages.MessageType.FloatMessageType, "packed[1]")
    softAssert(msgList[2].GetMessageType() == SmallMessages.MessageType.FloatMessageType, "packed[2]")
    softAssert(msgList[3].GetMessageType() == SmallMessages.MessageType.FloatMessageType, "packed[3]")
    softAssert(msgList[4].GetMessageType() == SmallMessages.MessageType.IntMessageType, "packed[4]")
    softAssert(msgList[5].GetMessageType() == SmallMessages.MessageType.EmptyMessageType, "packed[5]")
    softAssert(msgList[6].GetMessageType() == SmallMessages.MessageType.LongMessageType, "packed[6]")
    softAssert(msgList[7].GetMessageType() == SmallMessages.MessageType.LongMessageType, "packed[7]")
    softAssert(msgList[8].GetMessageType() == SmallMessages.MessageType.LongMessageType, "packed[8]")
    softAssert(msgList[9].GetMessageType() == SmallMessages.MessageType.IntMessageType, "packed[9]")
}


if (!OK) {
    "Failed assertions.\n".data(using: .utf8).map(FileHandle.standardError.write)
    exit(1)
}
