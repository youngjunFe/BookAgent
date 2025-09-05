# 🚀 Flutter 웹앱 배포 가이드

## 📦 1단계: 새로 빌드하기

수정된 코드를 반영하기 위해 새로 빌드:

```bash
# 프로젝트 루트에서 실행
flutter clean
flutter pub get
flutter build web --release
```

## 🌐 2단계: 배포 옵션 선택

### Option 1: Netlify 배포 (추천)
```bash
# Netlify CLI 사용
npm install -g netlify-cli
netlify deploy --prod --dir=build/web
```

또는 **Netlify 웹 대시보드**에서:
1. Sites → Add new site → Deploy manually
2. `build/web` 폴더를 드래그 앤 드롭

### Option 2: Vercel 배포  
```bash
# Vercel CLI 사용
npm install -g vercel
vercel --prod
```

또는 **Vercel 웹 대시보드**에서:
1. New Project → Import Git Repository
2. 자동으로 `build/web` 감지하여 배포

### Option 3: Railway 배포
```bash
# Railway CLI 사용  
npm install -g @railway/cli
railway login
railway deploy
```

### Option 4: GitHub Pages (무료)
```bash
# GitHub repository에 push하면 자동 배포
git add .
git commit -m "🔥 닉네임 생성 시스템 최적화 - API 호출 제거"
git push origin main
```

## ⚡ 빠른 배포 (현재 권장)

**기존 배포 서비스가 이미 연결되어 있다면:**

```bash
# 1. 새로 빌드
flutter build web --release

# 2. Git에 커밋 & 푸시 (자동 배포 트리거)
git add .
git commit -m "🔥 닉네임 시스템 최적화 완료
- 외부 API 호출 제거
- DB 트리거 방식으로 변경  
- 회원가입 속도 개선"
git push origin main
```

## 🔍 배포 후 테스트 체크리스트

### ✅ 필수 테스트:
- [ ] **회원가입**: 새 계정 생성시 자동으로 프로필 생성됨
- [ ] **닉네임 확인**: `독서가####` 형태로 생성됨  
- [ ] **중복 체크**: 동일한 닉네임으로 재가입시 다른 번호 생성
- [ ] **OAuth 로그인**: Google/Kakao 로그인 정상 작동
- [ ] **성능**: 회원가입 속도 개선됨 (API 호출 없음)

### 🔧 문제 발생시:
1. **브라우저 캐시 삭제** (Ctrl+F5 또는 Cmd+Shift+R)
2. **Supabase 콘솔**에서 새 가입자 프로필 확인
3. **브라우저 개발자 도구** → Network 탭에서 불필요한 API 호출 제거 확인

## 📱 모바일 앱 배포 (선택사항)

### Android APK 빌드:
```bash
flutter build apk --release
# APK 파일: build/app/outputs/flutter-apk/app-release.apk
```

### iOS 앱 빌드 (macOS에서):
```bash
flutter build ios --release
# Xcode에서 Archive → App Store Connect 업로드
```

## 🎯 배포 완료 후 확인사항

### 성능 개선 확인:
- ⚡ **회원가입 속도**: 외부 API 호출 제거로 빨라짐
- 🔒 **안정성**: DB 트리거 방식으로 더 안정적
- 🎯 **중복 방지**: 확실한 닉네임 중복 체크

### 사용자 경험:
- ✅ 회원가입 즉시 프로필 생성
- ✅ 예쁜 닉네임 자동 생성 (`독서가1234` 등)
- ✅ 빠르고 안정적인 로그인 프로세스

---

**🎉 배포 완료되면 모든 닉네임 생성 문제가 해결됩니다!**
