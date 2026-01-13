# windows-dev-shortcuts

Windows 환경에서 자주 사용하는 개발·운영 작업을 **메뉴 기반으로 빠르게 실행**하기 위한
Batch Script 기반 런처입니다.

하나의 `menu.bat` 실행으로 다음 작업들을 한 번에 처리할 수 있습니다.

-   지정한 디렉터리를 **VS Code / Cursor** 등 에디터로 열기
-   **CMD / PowerShell** (일반 / 관리자 권한) 실행
-   미리 등록한 서버로 **SSH 접속**
-   디렉터리 목록 자동 갱신, 별칭 변경, 검색

---

## ✨ 주요 기능

### 1️⃣ 에디터 실행 (동적 설정)

-   `settings.txt`에서 에디터 종류를 설정
-   메뉴에 에디터 이름이 그대로 표시됨
-   선택한 프로젝트 디렉터리를 즉시 열기

지원 예:

-   VS Code
-   Cursor
    (그 외 CLI 실행 가능한 에디터도 설정 가능)

---

### 2️⃣ 터미널 실행

-   CMD / PowerShell
-   일반 사용자 / 관리자 권한
-   Windows Terminal(`wt.exe`) 우선 사용, 없을 경우 자동 fallback

---

### 3️⃣ SSH 접속 관리

-   `ssh_map.txt`에 서버 정보 등록
-   번호 선택으로 SSH 접속
-   포트 지정 가능 (`user@host:port`)
-   주석(`#`) 및 빈 줄 무시 지원

---

### 4️⃣ 디렉터리 매핑 관리

-   프로젝트 디렉터리 목록 자동 스캔
-   별칭 유지한 채로 최신화
-   별칭 변경(Rename)
-   키워드 검색(Search)

---

## 📁 디렉터리 구조

```text
.
├─ menu.bat          # 메인 실행 스크립트
├─ settings.txt      # 전역 설정 파일
├─ dir_map.txt       # 에디터로 열 디렉터리 매핑
└─ ssh_map.txt       # SSH 서버 목록
```

---

## ⚙️ 설정 파일 설명

### settings.txt

```txt
CURSOR_BASE=C:\Users\gyelanjjim\Documents\workspace
SSH_BASE=C:\Users\gyelanjjim\Desktop\START

EDITOR_NAME=VSCODE
EDITOR_OPEN_COMMAND=code
```

| 항목                | 설명                      |
| ------------------- | ------------------------- |
| CURSOR_BASE         | 프로젝트 루트 디렉터리    |
| SSH_BASE            | ssh_map.txt가 위치한 경로 |
| EDITOR_NAME         | 메뉴에 표시될 에디터 이름 |
| EDITOR_OPEN_COMMAND | 실제 실행할 CLI 명령      |

#### 예시

```txt
EDITOR_NAME=CURSOR
EDITOR_OPEN_COMMAND=cursor
```

---

### dir_map.txt

```txt
backend-api=C:\Users\gyelanjjim\Documents\workspace\backend-api
frontend-web=C:\Users\gyelanjjim\Documents\workspace\frontend-web
```

형식:

```text
별칭=전체경로
```

-   `reLoad` 기능으로 자동 생성/갱신 가능
-   별칭 기준으로 정렬됨

---

### ssh_map.txt

```txt
# production
prod=user@10.0.0.1:22

# staging
staging=user@10.0.0.2
```

형식:

```text
별칭=user@host:port
```

-   포트 생략 시 기본값 `22`
-   `#` 로 시작하는 줄은 주석 처리

---

## 🖥️ 실행 방법

```bat
menu.bat
```

실행 후 메뉴 예시:

```text
1. VSCODE
2. SSH
cmd      - Open CMD (user)
cmd a    - Open CMD (admin)
ps       - Open PowerShell (user)
ps a     - Open PowerShell (admin)
x. Exit terminal
```

---

## ⌨️ 주요 단축 명령

| 입력  | 동작              |
| ----- | ----------------- |
| 1     | 에디터 메뉴       |
| 2     | SSH 메뉴          |
| cmd   | CMD 실행          |
| cmd a | 관리자 CMD        |
| ps    | PowerShell 실행   |
| ps a  | 관리자 PowerShell |
| x     | 종료              |

---

## 🔎 에디터 메뉴 기능

-   번호 선택 → 프로젝트 열기
-   `l` : 디렉터리 목록 Reload
-   `r` : 별칭 Rename
-   `s` : 키워드 검색
-   `f` : 메인 메뉴로 돌아가기

---

## ⚠️ 주의사항

-   `settings.txt`, `dir_map.txt`, `ssh_map.txt`는
    **공백 없는 `key=value` 형식**을 유지해야 합니다.
-   에디터 CLI 명령(`code`, `cursor`)은
    **환경 변수 PATH에 등록되어 있어야 합니다.**

---

## 💡 활용 예

-   여러 프로젝트를 빠르게 전환해야 하는 백엔드 개발자
-   Windows 서버 + SSH 운영 환경
-   개인 개발 환경 자동화
-   반복적인 터미널/에디터 실행 작업 최소화

---

## 📌 향후 확장 아이디어

-   에디터 옵션(`--new-window`) 설정 분리
-   PowerShell 버전 런처 제공
-   프로젝트별 `.env` 자동 로딩
-   WSL / Docker 컨텍스트 연동
