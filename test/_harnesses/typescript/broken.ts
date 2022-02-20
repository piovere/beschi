import { getDataView, writeBuffer, runTest } from "./util";

import * as BrokenMessages from '../../../out/generated/typescript/BrokenMessages';

const trunc = new BrokenMessages.TruncatedMessage();
trunc.x = 1.0;
trunc.y = 2.0;

function generate(filePath: string, softAssert: (condition: boolean, label: string) => void) {
    const data = new ArrayBuffer(1024);
    const dv = new DataView(data);
    const offset = trunc.WriteBytes(dv, 0, false);

    writeBuffer(Buffer.from(data, 0, offset), filePath);
}

function read(filePath: string, softAssert: (condition: boolean, label: string) => void) {
    const dv = getDataView(filePath);
    const input = BrokenMessages.FullMessage.FromBytes(dv, 0).val;

    softAssert(input == null, "reading broken message");
}


runTest(generate, read);
