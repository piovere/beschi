from collections import OrderedDict

import toml

BASE_TYPE_SIZES: dict[str, int] = {
    "byte":   1,
    "bool":   1,
    "uint16": 2,
    "int16":  2,
    "uint32": 4,
    "int32":  4,
    "uint64": 8,
    "int64":  8,
    "float":  4,
    "double": 8,
}

COLLECTION_TYPES: list[str] = [
    "list",
    "string",
]

class Protocol():
    def __init__(self, filename: str):
        self.namespace: str = None
        self.structs: OrderedDict = OrderedDict()
        self.messages: OrderedDict = OrderedDict()

        protocol_data = toml.load(filename)

        if "namespace" in protocol_data["meta"]:
            self.namespace = protocol_data["meta"]["namespace"]

        if "structs" in protocol_data:
            for struct_data in protocol_data["structs"]:
                if "_name" not in struct_data:
                    raise ValueError(f"Missing _name on {struct_data}")
                if struct_data["_name"] in self.structs:
                    raise ValueError(f"Duplicate _name on {struct_data}")
                self.structs[struct_data["_name"]] = []
            for struct in protocol_data["structs"]:
                struct_name = struct["_name"]
                for var_name, var_type in struct.items():
                    if (var_name[0] == "_"):
                        continue
                    if not self.verify_type_name(var_type):
                        raise NotImplementedError("No type called %s (definition: %s)" % (var_type, struct_name))
                    self.structs[struct_name].append((var_name, var_type))

        if "messages" in protocol_data:
            for message_data in protocol_data["messages"]:
                if "_name" not in message_data:
                    raise ValueError(f"Missing _name on {message_data}")
                if message_data["_name"] in self.messages:
                    raise ValueError(f"Duplicate _name on {message_data}")
                self.messages[message_data["_name"]] = []
            for message in protocol_data["messages"]:
                message_name = message["_name"]
                for var_name, var_type in message.items():
                    if (var_name[0] == "_"):
                        continue
                    if not self.verify_type_name(var_type):
                        raise NotImplementedError("No type called %s (message: %s)" % (var_type, message_name))
                    self.messages[message_name].append((var_name, var_type))

        if len(protocol_data["messages"]) > 255:
            raise ValueError("Cannot, at present, have more than 255 types of messages. Sorry. :(")

    def __str__(self) -> str:
        return f"Protocol (namespace: {self.namespace}, {len(self.structs)} structs, {len(self.messages)} messages)"

    def verify_type_name(self, type_name) -> bool:
        if type_name[0] == "[" and type_name[-1] == "]":
            type_name = type_name[1:-1]

        if type_name in BASE_TYPE_SIZES:
            return True
        if type_name in COLLECTION_TYPES:
            return True
        if type_name in self.structs:
            return True
        return False
