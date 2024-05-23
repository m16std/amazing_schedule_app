class User {
  final int id;
  final String username;
  final String password;
  final bool isAdmin;

  User({
    required this.id,
    required this.username,
    required this.password,
    required this.isAdmin,
  });

  // Метод для преобразования Map (полученного из базы данных) в объект User
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['cnt_login'],
      password: map['cnt_pass'],
      isAdmin: map['cnt_type'] == 1,
    );
  }

  // Метод для преобразования объекта User в Map (для вставки в базу данных)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cnt_login': username,
      'cnt_pass': password,
      'cnt_type': isAdmin ? 1 : 0,
    };
  }
}
