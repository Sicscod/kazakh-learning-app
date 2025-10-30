import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

<<<<<<< HEAD
class _MyAppState extends State<MyApp> {
  String currentLang = "kz";
=======
<<<<<<< HEAD


class HomePage extends StatelessWidget {
=======
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});
>>>>>>> fd9e0e37a2aee3b00172f8b2147f63a93d066e9c

  final greetings = {"kz": "СӘЛЕМ!", "ru": "ПРИВЕТ!", "en": "HELLO!"};
  final loginText = {"kz": "Кіру", "ru": "Войти", "en": "Login"};
  final registerText = {"kz": "Тіркелу", "ru": "Регистрация", "en": "Register"};

  void switchLang() {
    setState(() {
      if (currentLang == "kz") currentLang = "ru";
      else if (currentLang == "ru") currentLang = "en";
      else currentLang = "kz";
    });
  }

>>>>>>> a5b5d29b69f3c0216888454ca84e0dc52396f1d1
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

            // 🔹 Кнопка смены языка (lang.jpg)
            Positioned(
              top: 50,
              right: 20,
              child: GestureDetector(
                onTap: switchLang,
                child: Container(
                  width: 31,
                  height: 34,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(color: Colors.black, width: 1),
                    image: const DecorationImage(
                      image: AssetImage("assets/lang.jpg"),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),

            // 🔹 Текст “СӘЛЕМ!”
            Positioned(
              top: 326,
              left: 178,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Text(
                  greetings[currentLang]!,
                  key: ValueKey(currentLang),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w800,
                    fontSize: 48,
                    color: Color(0xFF32734E),
                    height: 1.0,
                  ),
                ),
              ),
            ),

            // 🔹 Прямоугольник под кнопкой "Тіркелу"
            Positioned(
              top: 398,
              left: 178,
              child: Container(
                width: 197,
                height: 47,
                decoration: BoxDecoration(
                  color: const Color(0xFF32734E),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            // 🔹 Кнопка “Тіркелу”
            Positioned(
              top: 403,
              left: 222,
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  width: 186,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBB03B),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    registerText[currentLang]!,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w800,
                      fontSize: 27,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ),

            // 🔹 Прямоугольник под кнопкой "Кіру"
            Positioned(
              top: 470,
              left: 178,
              child: Container(
                width: 197,
                height: 47,
                decoration: BoxDecoration(
                  color: const Color(0xFF32734E),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            // 🔹 Кнопка “Кіру”
            Positioned(
              top: 475,
              left: 249,
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  width: 186,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBB03B),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    loginText[currentLang]!,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w800,
                      fontSize: 27,
                      color: Colors.white,
                      height: 1.0,
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
