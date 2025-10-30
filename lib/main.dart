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

  final greetings = {"kz": "СӘЛЕМ!", "ru": "ПРИВЕТ!", "en": "HELLO!"};
  final loginText = {"kz": "кіру", "ru": "войти", "en": "login"};
  final registerText = {"kz": "тіркелу", "ru": "регистрация", "en": "register"};

  void switchLang() {
    setState(() {
      if (currentLang == "kz") {
        currentLang = "ru";
      } else if (currentLang == "ru") {
        currentLang = "en";
      } else {
        currentLang = "kz";
      }
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
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/leftsun.jpg"),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // 🔹 Текст “СӘЛЕМ!” без анимации
            Positioned(
              top: 326,
              left: 178,
              child: Text(
                greetings[currentLang]!,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w800,
                  fontSize: 48,
                  color: Color(0xFF32734E),
                  height: 1.0,
                ),
              ),
            ),

            // 🔹 Кнопка “Тіркелу”
            Positioned(
              top: 403,
              left: 178,
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  width: 197,
                  height: 47,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF32734E),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    registerText[currentLang]!,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w800,
                      fontSize: 27,
                      color: Color(0xFFFBB03B),
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ),

            // 🔹 Кнопка “Кіру”
            Positioned(
              top: 475,
              left: 178,
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  width: 197,
                  height: 47,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF32734E),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    loginText[currentLang]!,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w800,
                      fontSize: 27,
                      color: Color(0xFFFBB03B),
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ),

            // 🔹 Кнопка смены языка
            Positioned(
              top: 550,
              left: 344,
              child: GestureDetector(
                onTap: switchLang,
                child: Container(
                  width: 31,
                  height: 34,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    image: const DecorationImage(
                      image: AssetImage("assets/lang.jpg"),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
