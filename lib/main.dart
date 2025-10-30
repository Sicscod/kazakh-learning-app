import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String currentLang = "kz";

  final greetings = {
    "kz": "Сәлем!",
    "ru": "Привет!",
    "en": "Hello!"
  };

  final loginText = {
    "kz": "Кіру",
    "ru": "Войти",
    "en": "Login"
  };

  final registerText = {
    "kz": "Тіркелу",
    "ru": "Регистрация",
    "en": "Register"
  };

  void switchLang() {
    setState(() {
      if (currentLang == "kz") currentLang = "ru";
      else if (currentLang == "ru") currentLang = "en";
      else currentLang = "kz";
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Stack(
          children: [
            // 🔹 Фон
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/leftsun.jpg"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // 🔹 Кнопка смены языка (вверху)
            Positioned(
              top: 50,
              right: 20,
              child: GestureDetector(
                onTap: switchLang,
                child: Image.asset(
                  "assets/lang.jpg",
                  width: 50,
                  height: 50,
                ),
              ),
            ),
            // 🔹 Центр
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    greetings[currentLang]!,
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(color: Colors.black54, blurRadius: 6),
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),
                  // 🔹 Кнопки регистрации и входа
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black.withOpacity(0.6),
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          registerText[currentLang]!,
                          style: const TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 20),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black.withOpacity(0.6),
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          loginText[currentLang]!,
                          style: const TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
