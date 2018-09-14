class Profile {
  const Profile(this.id,this.name);

  final String name;
  final int id;

  int get hashCode => name.hashCode;

  bool operator==(Object other) => other is Profile && other.name == name;
}