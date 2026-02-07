# Firebase 설정 가이드

## 1. Firebase 프로젝트 생성

1. [Firebase Console](https://console.firebase.google.com/) 접속
2. **프로젝트 만들기** 클릭
3. 프로젝트 이름 입력: `baby-food-app`
4. Google Analytics 설정 (선택사항)
5. 프로젝트 생성 완료

## 2. Flutter 앱 추가

### FlutterFire CLI 사용 (권장)

```bash
# FlutterFire CLI 설치
dart pub global activate flutterfire_cli

# Firebase 프로젝트와 연결
flutterfire configure --project=your-project-id
```

### 수동 설정

#### Android
1. Firebase Console > 프로젝트 설정 > 앱 추가 > Android
2. 패키지 이름: `com.babyfood.baby_food_app`
3. `google-services.json` 다운로드
4. `android/app/` 폴더에 복사

#### iOS
1. Firebase Console > 프로젝트 설정 > 앱 추가 > iOS
2. 번들 ID: `com.babyfood.babyFoodApp`
3. `GoogleService-Info.plist` 다운로드
4. `ios/Runner/` 폴더에 복사

#### Web
1. Firebase Console > 프로젝트 설정 > 앱 추가 > Web
2. 앱 닉네임 입력
3. 표시된 설정 코드를 `web/index.html`에 추가

## 3. Firebase 서비스 활성화

### Authentication
1. Firebase Console > Authentication > 시작하기
2. Sign-in method > **이메일/비밀번호** 활성화

### Cloud Firestore
1. Firebase Console > Firestore Database > 데이터베이스 만들기
2. **프로덕션 모드**로 시작
3. 위치: `asia-northeast3` (서울)

## 4. Firestore 보안 규칙

Firebase Console > Firestore Database > 규칙 에서 다음 규칙 적용:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // 식재료: 모두 읽기 가능, 쓰기는 관리자만
    match /ingredients/{ingredientId} {
      allow read: if true;
      allow write: if false; // 관리자 콘솔에서만 관리
    }

    // 기본 레시피: 모두 읽기 가능
    match /recipes/{recipeId} {
      // 기본 레시피 (userId가 null)는 모두 읽기 가능
      allow read: if resource.data.userId == null;

      // 사용자 레시피는 본인만 읽기/쓰기 가능
      allow read: if resource.data.userId == request.auth.uid;
      allow create: if request.auth != null
                    && request.resource.data.userId == request.auth.uid;
      allow update, delete: if request.auth != null
                            && resource.data.userId == request.auth.uid;
    }

    // 사용자 정보: 본인만 접근 가능
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## 5. 초기 데이터 업로드

앱 첫 실행 시 또는 Firebase Console에서 직접 데이터를 추가합니다.

### Firestore 데이터 구조

```
firestore/
├── ingredients/          # 식재료 컬렉션
│   ├── rice
│   │   ├── id: "rice"
│   │   ├── name: "쌀 (백미)"
│   │   ├── category: 0  (grain)
│   │   ├── nutritionPer100g: {...}
│   │   ├── availableStages: [0, 1, 2]
│   │   └── ...
│   └── ...
│
├── recipes/              # 레시피 컬렉션
│   ├── rice_porridge
│   │   ├── id: "rice_porridge"
│   │   ├── name: "쌀미음"
│   │   ├── stage: 0  (early)
│   │   ├── ingredientData: [{ingredientId: "rice", amount: 10, unit: "g"}]
│   │   ├── steps: [...]
│   │   ├── userId: null  (기본 레시피)
│   │   └── ...
│   └── ...
│
└── users/                # 사용자 컬렉션
    └── {userId}
        ├── email: "user@example.com"
        ├── displayName: "홍길동"
        ├── favoriteRecipes: ["rice_porridge", ...]
        └── createdAt: Timestamp
```

## 6. Firebase 초기화 코드

`lib/firebase_options.dart` 파일이 FlutterFire CLI로 자동 생성됩니다.

`main.dart`에서 Firebase 초기화:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const BabyFoodApp());
}
```

## 7. 테스트

1. 앱 실행
2. 회원가입 테스트
3. 로그인 테스트
4. 레시피 저장/수정/삭제 테스트

## 문제 해결

### "Firebase 초기화 실패" 오류
- `google-services.json` 또는 `GoogleService-Info.plist` 파일 위치 확인
- 패키지/번들 ID가 Firebase 설정과 일치하는지 확인

### "Permission Denied" 오류
- Firestore 보안 규칙 확인
- 사용자가 로그인되어 있는지 확인

### 웹에서 작동 안함
- `web/index.html`에 Firebase SDK 스크립트 추가 확인
