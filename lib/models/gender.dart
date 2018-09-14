class Gender {
  const Gender(this.id,this.name);

  final String name;
  final int id;

  int get hashCode => name.hashCode;

  bool operator==(Object other) => other is Gender && other.name == name;
}