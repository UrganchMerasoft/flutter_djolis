class Order {
  int id;
  int checkNumber;
  int statusCode;
  int price;
  String notes;
  String name;
  String date;

  Order({
    required this.id,
    required this.checkNumber,
    required this.statusCode,
    required this.price,
    required this.notes,
    required this.name,
    required this.date,
  });
}