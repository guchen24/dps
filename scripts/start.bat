@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "ROOT=%~dp0.."
for %%I in ("%ROOT%") do set "ROOT=%%~fI"
set "DOCKER_DIR=%ROOT%\docker"
set "EXE=%ROOT%\src-tauri\target\release\DeepSeek Harness Desktop.exe"

where docker >nul 2>nul
if errorlevel 1 (
  echo Docker is not installed. Download it from https://www.docker.com/products/docker-desktop/
  exit /b 1
)

docker info >nul 2>nul
if errorlevel 1 (
  echo Docker Desktop is not running. Starting it now...
  if exist "%ProgramFiles%\Docker\Docker\Docker Desktop.exe" start "" "%ProgramFiles%\Docker\Docker\Docker Desktop.exe"
  set /a ATTEMPT=0
  :wait_docker
  set /a ATTEMPT+=1
  ping -n 3 127.0.0.1 >nul
  docker info >nul 2>nul && goto docker_ready
  if !ATTEMPT! LSS 30 goto wait_docker
  echo Docker Desktop did not become ready within 60 seconds.
  exit /b 1
)

:docker_ready
set "BACKEND_RUNNING="
set "STATUS_FILE=%TEMP%\dsh-harness-status-%RANDOM%.txt"
docker ps --filter "name=dsh-harness-backend" --format "{{.Names}}" > "%STATUS_FILE%" 2>nul
if exist "%STATUS_FILE%" set /p BACKEND_RUNNING=<"%STATUS_FILE%"
if exist "%STATUS_FILE%" del "%STATUS_FILE%" >nul 2>nul
if /I not "%BACKEND_RUNNING%"=="dsh-harness-backend" (
  if not exist "%DOCKER_DIR%\.env" (
    copy "%DOCKER_DIR%\.env.example" "%DOCKER_DIR%\.env" >nul
    echo Created docker\.env. Edit DEEPSEEK_API_KEY before using model requests.
  )
  pushd "%DOCKER_DIR%"
  docker compose up -d --build
  if errorlevel 1 (
    popd
    exit /b 1
  )
  popd
)

set /a ATTEMPT=0
:wait_backend
set /a ATTEMPT+=1
curl.exe --fail --silent http://127.0.0.1:3080/ >nul 2>nul && goto backend_ready
if !ATTEMPT! LSS 30 (
  ping -n 3 127.0.0.1 >nul
  goto wait_backend
)
echo Docker backend did not become ready within 60 seconds.
exit /b 1

:backend_ready
if not exist "%EXE%" (
  echo Desktop executable was not found: %EXE%
  echo Build it first with: cargo tauri build
  exit /b 1
)
start "" "%EXE%"
