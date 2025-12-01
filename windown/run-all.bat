@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul
:: Tiêu đề cửa sổ
title DFO Miner Automation Tool

:: --- CẤU HÌNH ---
set EXECUTABLE=main_dfo_win.exe

:: --- HÀM IN TIÊU ĐỀ ---
goto :Start

:PrintHeader
echo.
echo ============================================================
echo    %~1
echo ============================================================
echo.
exit /b 0

:Start
:: --- BƯỚC 1: KIỂM TRA VÀ TẠO FILE .ENV ---
call :PrintHeader "Buoc 1: Cau hinh moi truong (.env)"

set CREATE_ENV=false

if exist .env (
    echo [WARN] File .env da ton tai.
    set /p overwrite_ans="Ban co muon tao lai (ghi de) file .env khong? [y/N]: "
    if /i "!overwrite_ans!"=="y" set CREATE_ENV=true
) else (
    echo [WARN] Chua tim thay file .env.
    set CREATE_ENV=true
)

if "!CREATE_ENV!"=="true" (
    echo [INFO] Bat dau cau hinh file .env moi...
    
    set MNEMONIC_VAL=
    set /p create_seed_ans="Ban co muon tao Seed Phrase (24 ky tu) moi bang lenh '%EXECUTABLE% create' khong? [y/N]: "
    
    if /i "!create_seed_ans!"=="y" (
        echo [INFO] Dang chay lenh tao vi...
        echo --------------------------------------------------
        %EXECUTABLE% create
        echo --------------------------------------------------
        echo [QUAN TRONG] Hay COPY doan Seed Phrase (24 tu) hien ra o tren.
        echo (Windows CMD kho tu dong bat Regex, nen ban vui long copy tay nhe).
        echo.
    )

    :AskMnemonic
    set /p input_mnemonic="=> Nhap MNEMONIC (Paste chuoi 24 tu vao day): "
    if "!input_mnemonic!"=="" goto AskMnemonic
    set MNEMONIC_VAL=!input_mnemonic!

    :: Nhap cac tham so khac
    set /p input_dest_wallet="=> Nhap DESTINATION_WALLET_ADDRESS (Bat buoc): "
    set DESTINATION_WALLET_ADDRESS=!input_dest_wallet!

    set AMOUNT_ACCOUNT=50
    set /p input_amount="=> Nhap AMOUNT_ACCOUNT (Mac dinh: 50): "
    if not "!input_amount!"=="" set AMOUNT_ACCOUNT=!input_amount!

    set ACCOUNT_INDEX_START=1
    set /p input_index="=> Nhap ACCOUNT_INDEX_START (Mac dinh: 1): "
    if not "!input_index!"=="" set ACCOUNT_INDEX_START=!input_index!

    set RUST_THREADS=10
    set /p input_threads="=> Nhap RUST_THREADS (Mac dinh: 10): "
    if not "!input_threads!"=="" set RUST_THREADS=!input_threads!

    set DEFAULT_MAX_SOLVERS=1
    set /p input_solvers="=> Nhap DEFAULT_MAX_SOLVERS (Mac dinh: 1): "
    if not "!input_solvers!"=="" set DEFAULT_MAX_SOLVERS=!input_solvers!

    :: Ghi noi dung vao file .env
    (
        echo #--- BAT BUOC ---
        echo MNEMONIC="!MNEMONIC_VAL!"
        echo.
        echo # --- CAU HINH SO LUONG VI ---
        echo AMOUNT_ACCOUNT=!AMOUNT_ACCOUNT!
        echo ACCOUNT_INDEX_START=!ACCOUNT_INDEX_START!
        echo # So luong CPU danh cho moi tien trinh giai
        echo RUST_THREADS=!RUST_THREADS!
        echo DEFAULT_MAX_SOLVERS=!DEFAULT_MAX_SOLVERS!
        echo.
        echo # --- CAU HINH DONATE ---
        echo DESTINATION_WALLET_ADDRESS=!DESTINATION_WALLET_ADDRESS!
        echo.
        echo # Thong diep ky khi dang ky
        echo REGISTER_MESSAGE="I agree to abide by the terms and conditions as described in version 1-0 of the Defensio DFO mining process: 2da58cd94d6ccf3d933c4a55ebc720ba03b829b84033b4844aafc36828477cc0"
        echo REGISTRATION_HASH="2da58cd94d6ccf3d933c4a55ebc720ba03b829b84033b4844aafc36828477cc0"
        echo REGISTRATION_VERSION="1-0"
        echo # Tin nhan Donate ^(Phan co dinh truoc dia chi vi^)
        echo # Night/DFO dung: "Assign accumulated Scavenger rights to: "
        echo DONATE_MESSAGE_PREFIX="Assign accumulated Scavenger rights to: "
        echo.
        echo # --- CAU HINH GIAO DIEN ^& DAO ---
        echo TOKEN_SYMBOL="DFO"
        echo TOKEN_JSON_KEY="dfo_allocation"
    ) > .env

    echo [OK] Da tao file .env thanh cong!
) else (
    echo [INFO] Giu nguyen file .env cu.
)

:: --- BƯỚC 2: ĐĂNG KÝ (REGISTER) ---
call :PrintHeader "Buoc 2: Dang ky (Register)"
set /p reg_ans="Ban co muon chay lenh Dang ky (Register) khong? [y/N]: "
if /i "!reg_ans!"=="y" (
    echo [INFO] Dang chay %EXECUTABLE% register...
    %EXECUTABLE% register
) else (
    echo [SKIP] Bo qua buoc Register.
)

:: --- BƯỚC 3: QUYÊN GÓP (DONATE) ---
call :PrintHeader "Buoc 3: Quyen gop (Donate)"
set /p donate_ans="Ban co muon chay lenh Quyen gop (Donate) khong? [y/N]: "
if /i "!donate_ans!"=="y" (
    echo [INFO] Dang chay %EXECUTABLE% donate...
    %EXECUTABLE% donate
) else (
    echo [SKIP] Bo qua buoc Donate.
)

:: --- BƯỚC 4: CHẠY MINER (RUN) ---
call :PrintHeader "Buoc 4: Kiem tra va Chay Miner"

if exist "challenges.json" (
    echo [OK] Tim thay file challenges.json.
    echo [START] Khoi dong Miner chinh ^(%EXECUTABLE% run^)...
    %EXECUTABLE% run
) else (
    echo [ERROR] Loi: Khong tim thay file 'challenges.json'.
    echo [HINT] Vui long kiem tra lai quy trinh hoac chay lai file nay de thuc hien buoc Register/Donate neu can.
    pause
    exit /b 1
)

echo.
echo [DONE] Script hoan tat.
pause
