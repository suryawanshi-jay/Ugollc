class AddressType {
  const AddressType(this.id,this.name);

  final String name;
  final int id;

  int get hashCode => name.hashCode;

  bool operator==(Object other) => other is AddressType && other.name == name;
}