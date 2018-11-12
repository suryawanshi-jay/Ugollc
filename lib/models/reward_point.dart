class RewardPoint {
  String description;
  int points;

  RewardPoint(this.description,this.points);

  RewardPoint.fromJSON(Map json) {
    description = json["description"];
    points = json["points"];
  }
}