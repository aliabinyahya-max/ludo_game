# المرحلة التنفيذية 1 — معالجة عوائق بناء Android

التاريخ: 2026-11-10
الفرع: `feat/3d-board-animations-phase-03-04-20261110`
النطاق: تدقيق إعدادات Android/Gradle/Flutter/SDK وتهيئة CI فقط.
حالة البناء: **ممنوع في هذه المرحلة**؛ إذن البناء الوحيد السابق استُهلك وفشل.

## 1. خط الأساس الذي تمت مراجعته

| العنصر | القيمة | النتيجة |
|---|---:|---|
| Flutter CI | 3.44.9 stable | مثبت في workflow |
| Java | 17 | مثبت في workflow |
| AGP | 8.11.1 | متوافق مع Gradle 8.13+ وJDK 17 |
| Kotlin Gradle plugin | 2.2.20 | متوافق بالكامل مع AGP حتى 8.11.1 وGradle حتى 8.14 |
| Gradle wrapper | 8.14.3 | أعلى من حد AGP الأدنى؛ ضمن خط Gradle 8.14 |
| compile SDK | 36 | يعالج متطلب plugin الذي ظهر في سجل البناء |
| Build Tools | 35.0.0 | أصبح مثبتاً ومتحققاً منه في CI |
| NDK | 28.2.13676358 | pinned في app Gradle، وأضيف تثبيته الصريح إلى CI |
| CMake | 3.31.4 | يعالج غيابه الذي تسبب في فشل flutter_angle |
| min/target SDK | 21 / 34 | لم يتغيرا |

## 2. سبب الفشل السابق

- فشل تاريخي أقدم بسبب AGP 8.2.1 الأقل من الحد المطلوب بواسطة Flutter 3.44.9؛ تمت معالجته سابقاً برفع AGP إلى 8.11.1.
- المحاولة الوحيدة المصرح بها لاحقاً توقفت في `:flutter_angle:configureCMakeDebug[arm64-v8a]` بسبب عدم تثبيت CMake 3.31.4 في runner.
- ظهر في السجل نفسه أن `shared_preferences_android` يتطلب compile SDK 36؛ تم رفع compile SDK إلى 36.
- لم ينتج APK ولم يرفع Artifact. لم تتم محاولة بناء ثانية.

## 3. التعديلات المنفذة الآن

1. تعديل `.github/workflows/build.yml`:
   - تثبيت Android command-line tools عبر `android-actions/setup-android@v3`.
   - تثبيت وقبول تراخيص Android SDK.
   - تثبيت Android platform 36 وBuild Tools 35.0.0 وNDK 28.2.13676358 وCMake 3.31.4 وplatform-tools.
   - التحقق آلياً من ظهور كل حزمة في `sdkmanager --list_installed`.
   - الإبقاء على `flutter pub get` و`flutter analyze` و`flutter test`.
   - إزالة مهمة APK build ورفع artifact نهائياً من workflow الحالي؛ لن تعمل مهمة بناء تلقائياً عند push أو workflow_dispatch.
2. تحديث `docs/ANDROID_BUILD_BLOCKER_FIX.md` لتوثيق الأسباب والإصلاحات وحدود التحقق.
3. تحديث `docs/PHASE_10_ANDROID_RELEASE_READINESS.md` مع القيم الحالية والنواقص.
4. هذا التقرير يوثق المرحلة التنفيذية 1.

## 4. ما لم يتغير عمداً

- لم يتم تعديل package ID أو namespace `com.example.ludo_game` لعدم اعتماد معرّف نهائي.
- لم يتم تغيير إعدادات التوقيع؛ Release ما زال يستخدم debug signing ويحتاج قراراً منفصلاً وإعداد keystore محمي.
- لم يتم تغيير target SDK 34 قبل مراجعة سياسة النشر.
- لم يتم تغيير NDK أو CMake في إعدادات التطبيق؛ تم جعل CI يثبت الإصدارات المحددة مسبقاً.
- لا merge ولا release ولا نشر.

## 5. التحقق وحدوده

بعد التعديلات المصدرية، يجب أن يثبت تشغيل CI العادي ما يلي:
- تثبيت الحزم المطلوبة من SDK manager.
- اكتمال `flutter pub get`.
- نجاح `flutter analyze`.
- نجاح `flutter test`.

هذا التحقق لا يشغّل Gradle ولا يترجم Android ولا يثبت أن CMake/NDK يعملان فعلياً أثناء بناء flutter_angle. لا يوجد APK/AAB، ولا اختبار جهاز فعلي. ولا يجوز تفسير نجاح preflight بأنه نجاح بناء.

## 6. المراجع الرسمية للتوافق

- Android Gradle Plugin compatibility: https://developer.android.com/build/releases/about-agp
- AGP 8.11 release notes: https://developer.android.com/build/releases/agp-8-11-0-release-notes
- Kotlin Gradle plugin compatibility: https://kotlinlang.org/docs/gradle-configure-project.html

## 7. الحكم النهائي

**المرحلة 1: تنفيذ المصدر وتهيئة CI مكتملان. اعتماد التحقق الآلي ينتظر تشغيل CI.**

تمت معالجة نقص تثبيت CMake وNDK من ناحية إعداد CI، وأزيل خطر إعادة تشغيل البناء المستهلك تلقائياً. يبقى البناء الفعلي غير مثبت ويحتاج إذناً جديداً مستقلاً من المستخدم في المرحلة التنفيذية المخصصة له.


## متابعة نتيجة CI بعد التقرير الأول

- Run #207 فشل في `android-actions/setup-android@v3` قبل تثبيت الحزم؛ حاولت الإضافة تثبيت حزمة SDK قديمة باسم `tools` غير متاحة.
- لم يبدأ تثبيت NDK/CMake ولم تبدأ اختبارات Flutter في ذلك التشغيل.
- الإصلاح الإضافي: إزالة الاعتماد على action الذي يطلب الحزمة القديمة، واستخدام Android SDK command-line tools المثبتة مسبقاً على GitHub-hosted Ubuntu runner، مع تحديد مسار `sdkmanager` والتحقق من إصداره قبل تثبيت الحزم المطلوبة.
- Commit الإصلاح: `b6bf7ec398922dc0f4cd5373eb1174ca9cb98761`.
- النتيجة الجديدة لم تُعتمد بعد؛ يلزم اكتمال CI التالي.

## متابعة CI رقم 213/214 — إصلاح خطأ قبول التراخيص

- التشغيلان `42780479279` (push) و`42780483585` (pull_request) فشلا في الخطوة `Install and verify Android SDK components`، قبل `flutter pub get` والتحليل والاختبارات.
- السجل أكد أن `sdkmanager --licenses` وصل إلى `All SDK package licenses accepted`، ثم انتهت الخطوة بالخطأ `yes: standard output: Broken pipe` ورمز خروج 1.
- السبب الجذري: تفعيل `set -o pipefail` جعل SIGPIPE الطبيعي لأمر `yes` (بعد أن أغلق sdkmanager الإدخال عقب قبول التراخيص) يفشل الـ pipeline، رغم نجاح sdkmanager نفسه. هذا ليس رفضاً للتراخيص ولا نقصاً في حزم SDK.
- الإصلاح في `.github/workflows/build.yml`: تعطيل `pipefail` مؤقتاً لخطوة `yes | sdkmanager --licenses` فقط، وقراءة `PIPESTATUS[1]` للتحقق من رمز خروج sdkmanager الحقيقي، ثم إعادة `pipefail` قبل بقية الأوامر. بذلك لا يتم تجاهل فشل sdkmanager.
- Commit الإصلاح: `31dea195c8058eed8ea5aec7675083fbbf3a8250`.
- الحالة بعد الإصلاح: بانتظار تشغيل CI جديد. لا يمكن إعلان النجاح قبل أن تمر خطوة تثبيت/التحقق ثم `flutter pub get` و`flutter analyze` و`flutter test`.
- لم يتم تشغيل Gradle أو بناء APK/AAB أو اختبار جهاز؛ إذن البناء السابق لا يزال مستهلكاً.