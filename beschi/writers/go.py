import sys
import re
import copy
from collections import OrderedDict

from ..protocol import Protocol, BASE_TYPE_SIZES, COLLECTION_TYPES
from ..writer import Writer
from .. import LIB_NAME, LIB_VERSION

LANGUAGE_NAME = "Go"


class GoWriter(Writer):
    language_name = LANGUAGE_NAME
    default_extension = ".go"

    def __init__(self, p: Protocol):
        # because of how Go handles making methods/members public, we need to
        #   do some rewriting on the protocol here
        def publicize(s: str):
            return s[:1].upper() + s[1:]

        p2 = copy.deepcopy(p)
        nstructs = OrderedDict()
        for s in p2.structs:
            k = publicize(s)
            v = []
            for vdata in p2.structs[s]:
                v.append( (publicize(vdata[0]), vdata[1]) )
            nstructs[k] = v
        p2.structs = nstructs

        nmessages = OrderedDict()
        for m in p2.messages:
            k = publicize(m)
            v = []
            for vdata in p2.messages[m]:
                v.append( (publicize(vdata[0]), vdata[1]) )
            nmessages[k] = v
        p2.messages = nmessages

        super().__init__(protocol=p2, tab="\t")

        self.type_mapping["byte"] = "byte"
        self.type_mapping["bool"] = "bool"
        self.type_mapping["uint16"] = "uint16"
        self.type_mapping["int16"] = "int16"
        self.type_mapping["uint32"] = "uint32"
        self.type_mapping["int32"] = "int32"
        self.type_mapping["uint64"] = "uint64"
        self.type_mapping["int64"] = "int64"
        self.type_mapping["float"] = "float32"
        self.type_mapping["double"] = "float64"



    def simple(self, var_type: str) -> bool:
        if var_type in BASE_TYPE_SIZES:
            return True
        elif var_type in COLLECTION_TYPES:
            return False
        elif var_type[0] == "[" and var_type[-1] == "]":
            return False
        elif var_type in self.protocol.structs or var_type in self.protocol.messages:
            datums: list[tuple[str,str]] = None
            if var_type in self.protocol.structs:
                datums = self.protocol.structs[var_type]
            else:
                datums = self.protocol.messages[var_type]
            for _, vt in datums:
                if not self.simple(vt):
                    return False
            return True
        else:
            raise NotImplementedError("Can't determine simplicity of %s." % var_type)

    def deserializer(self, var_type: str, var_name: str, parent: str = None) -> list[str]:
        if parent == None:
            pref = ""
            ptr = ""
            this = "input"
        else:
            pref = "%s." % parent
            ptr = "&"
            this = pref + var_name
        label = var_name
        if label.endswith("[i]"):
            label = "i"

        if self.simple(var_type):
            return ["binary.Read(data, binary.LittleEndian, %s%s%s)" % (ptr, pref, var_name)]
        elif var_type in self.protocol.structs or var_type in self.protocol.messages:
            fields: list[tuple[str,str]] = None
            if var_type in self.protocol.structs:
                fields = self.protocol.structs[var_type]
            elif var_type in self.protocol.messages:
                fields = self.protocol.messages[var_type]
            output: list[str] = []
            for vn, vt in fields:
                output += self.deserializer(vt, vn, this)
            return output
        elif var_type == "string":
            return ["readString(data, %s%s%s)" % (ptr, pref, var_name)]
        elif var_type[0] == "[" and var_type[-1] == "]":
            interior = var_type[1:-1]
            out = [
                "var %sLen uint32" % label,
                "binary.Read(data, binary.LittleEndian, &%sLen)" % label,
                "%s%s = make([]%s, %sLen)" % (pref, var_name, interior, label),
                "for i := (uint32)(0); i < %sLen; i++ {" % label
            ]
            out += [
                self.tab + deser for deser in self.deserializer(interior, "%s[i]" % (var_name), parent)
            ]
            out += ["}"]
            return out
        else:
            raise NotImplementedError("Type %s not deserializable yet." % var_type)


    def serializer(self, var_type: str, var_name: str, parent: str = None) -> list[str]:
        if parent == None:
            pref = ""
            ptr = ""
            this = "output"
        else:
            pref = "%s." % parent
            ptr = "&"
            this = pref + var_name
        label = var_name
        if label.endswith("[i]"):
            label = "i"

        if self.simple(var_type):
            return ["binary.Write(data, binary.LittleEndian, %s%s%s)" % (ptr, pref, var_name)]
        elif var_type in self.protocol.structs or var_type in self.protocol.messages:
            fields: list[tuple[str,str]] = None
            if var_type in self.protocol.structs:
                fields = self.protocol.structs[var_type]
            elif var_type in self.protocol.messages:
                fields = self.protocol.messages[var_type]
            output: list[str] = []
            for vn, vt in fields:
                output += self.serializer(vt, vn, this)
            return output
        elif var_type == "string":
            return ["writeString(data, %s%s%s)" % (ptr, pref, var_name)]
        elif var_type[0] == "[" and var_type[-1] == "]":
            interior = var_type[1:-1]
            out = [
                "%sLen := (uint32)(len(%s%s))" % (label, pref, var_name),
                "binary.Write(data, binary.LittleEndian, %sLen)" % label,
                "for i := (uint32)(0); i < %sLen; i++ {" % label
            ]
            out += [
                self.tab + deser for deser in self.serializer(interior, "%s[i]" % (var_name), parent)
            ]
            out += ["}"]
            return out
        else:
            raise NotImplementedError("Type %s not serializable yet." % var_type)


    def gen_struct(self, s: tuple[str, list[tuple[str,str]]]):
        self.write_line()
        self.write_line("type %s struct {" % s[0])
        self.indent_level += 1

        for var_name, var_type in s[1]:
            if var_type[0] == "[" and var_type[-1] == "]":
                self.write_line("%s []%s" % (var_name, self.get_var(var_type[1:-1])))
            else:
                self.write_line("%s %s" % (var_name, self.get_var(var_type)))
        self.indent_level -= 1
        self.write_line("}")
        self.write_line()

        self.write_line("func %sFromBytes (data io.Reader, input *%s) {" % (s[0], s[0]) )
        self.indent_level += 1
        [self.write_line(s) for s in self.deserializer(s[0], "input")]
        self.indent_level -= 1
        self.write_line("}")
        self.write_line()

        self.write_line("func (output %s) WriteBytes (data io.Writer) {" % (s[0]))
        self.indent_level += 1
        [self.write_line(s) for s in self.serializer(s[0], "output")]
        self.indent_level -= 1
        self.write_line("}")
        self.write_line()



    def gen_message(self, m: tuple[str, list[tuple[str,str]]]):
        self.gen_struct(m)

        self.write_line("func (output %s) GetMessageType() MessageType {" % (m[0]))
        self.indent_level += 1
        self.write_line("return %sType" % m[0])
        self.indent_level -= 1
        self.write_line("}")
        self.write_line()


    def generate(self) -> str:
        self.output = []

        self.write_line(f"// This file was automatically generated by {LIB_NAME} v{LIB_VERSION}.")
        self.write_line(f"// Do not edit directly.")
        self.write_line()
        if self.protocol.namespace:
            self.write_line("package %s" % self.protocol.namespace)
        else:
            self.write_line("package main")
        self.write_line()
        self.write_line("import (")
        self.indent_level += 1
        self.write_line("\"encoding/binary\"")
        self.write_line("\"io\"")
        self.indent_level -= 1
        self.write_line(")")
        self.write_line()

        msg_types = [mt for mt in self.protocol.messages.keys()]

        self.write_line("type MessageType byte")
        self.write_line("const (")
        self.indent_level += 1
        [self.write_line("%sType MessageType = %d" % (k, i+1)) for i, k in enumerate(msg_types)]
        self.indent_level -= 1
        self.write_line(")")
        self.write_line()

        self.write_line("type Message interface {")
        self.indent_level += 1
        self.write_line("GetMessageType() MessageType")
        self.write_line("WriteBytes(data io.Writer)")
        self.indent_level -= 1
        self.write_line("}")
        self.write_line()

        self.write_line("func ProcessRawBytes (data io.Reader) Message {")
        self.indent_level += 1
        self.write_line("var msgType MessageType")
        self.write_line("binary.Read(data, binary.LittleEndian, &msgType)")
        self.write_line("switch msgType {")
        for msg_type in msg_types:
            self.write_line("case %sType:" % msg_type)
            self.indent_level += 1
            self.write_line("var msg %s" % msg_type)
            self.write_line("%sFromBytes(data, &msg)" % msg_type)
            self.write_line("return msg")
            self.indent_level -= 1
        self.write_line("default:")
        self.indent_level += 1
        self.write_line("return nil")
        self.indent_level -= 1
        self.write_line("}")
        self.indent_level -= 1
        self.write_line("}")
        self.write_line()

        self.write_line("func readString(data io.Reader, str *string) {")
        self.indent_level += 1
        self.write_line("var len uint32")
        self.write_line("binary.Read(data, binary.LittleEndian, &len)")
        self.write_line("sbytes := make([]byte, len)")
        self.write_line("binary.Read(data, binary.LittleEndian, &sbytes)")
        self.write_line("*str = string(sbytes)")
        self.indent_level -= 1
        self.write_line("}")
        self.write_line()

        self.write_line("func writeString(data io.Writer, str *string) {")
        self.indent_level += 1
        self.write_line("strLen := (uint32)(len(*str))")
        self.write_line("binary.Write(data, binary.LittleEndian, strLen)")
        self.write_line("io.WriteString(data, *str)")
        self.indent_level -= 1
        self.write_line("}")
        self.write_line()

        for s in self.protocol.structs.items():
            self.gen_struct(s)

        for m in self.protocol.messages.items():
            self.gen_message(m)

        self.write_line()
        assert self.indent_level == 0

        return "\n".join(self.output)
