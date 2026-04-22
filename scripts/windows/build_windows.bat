@echo off
REM InkRoot Windows 发布构建脚本
REM 需要在Windows系统上运行

echo ========================================
echo    InkRoot Windows 发布构建工具
echo ========================================
echo.

REM 获取版本号
for /f "tokens=2" %%i in ('findstr "version:" pubspec.yaml') do set VERSION=%%i
set VERSION=%VERSION:~0,-6%
echo 当前版本: %VERSION%
echo.

REM 步骤1: 清理构建
echo [1/3] 清理旧构建...
flutter clean
echo.

REM 步骤2: 获取依赖
echo [2/3] 获取依赖...
flutter pub get
echo.

REM 步骤3: 构建应用
echo [3/3] 构建 Windows 应用...
flutter build windows --release
echo.

REM 检查构建结果
if exist "build\windows\x64\runner\Release\inkroot.exe" (
    echo ========================================
    echo 构建完成！
    echo ========================================
    echo.
    echo 应用位置: build\windows\x64\runner\Release\
    echo 可执行文件: inkroot.exe
    echo.
    echo 下一步:
    echo   1. 测试应用
    echo   2. 使用 Inno Setup 创建安装程序
    echo   3. 或使用 MSIX 打包为 Microsoft Store 应用
    echo.
) else (
    echo ========================================
    echo 构建失败！
    echo ========================================
    exit /b 1
)
