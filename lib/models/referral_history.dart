class ReferralHistory {
  String name;
  String email;
  DateTime date;

  ReferralHistory(this.name,this.email,this.date);

  ReferralHistory.fromJSON(Map json) {
    name = json["name"];
    email = json["email"];
    final _dateParts = json["date_added"].split("/");
    date = DateTime.parse("${_dateParts[2]}-${_dateParts[1]}-${_dateParts[0]}");
  }
}