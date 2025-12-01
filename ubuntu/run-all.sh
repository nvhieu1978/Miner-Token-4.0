#!/bin/bash

# --- Cấu hình màu sắc hiển thị ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "\n${BLUE}============================================================${NC}"
    echo -e "${BLUE}🚀  $1${NC}"
    echo -e "${BLUE}============================================================${NC}"
}

# --- BƯỚC 1: KIỂM TRA VÀ TẠO FILE .ENV ---
print_header "Bước 1: Cấu hình môi trường (.env)"

CREATE_ENV=false

if [ -f ".env" ]; then
    echo -e "${YELLOW}⚠️  File .env đã tồn tại.${NC}"
    read -p "❓ Bạn có muốn tạo lại (ghi đè) file .env không? [y/N]: " overwrite_ans
    if [[ "$overwrite_ans" =~ ^[Yy]$ ]]; then
        CREATE_ENV=true
    fi
else
    echo -e "${YELLOW}⚠️  Chưa tìm thấy file .env.${NC}"
    CREATE_ENV=true
fi

if [ "$CREATE_ENV" = true ]; then
    echo -e "${GREEN}>> Bắt đầu cấu hình file .env mới...${NC}"
    
    MNEMONIC_VAL=""
    read -p "❓ Bạn có muốn tạo Seed Phrase (24 ký tự) mới bằng lệnh './dfo_miner_ubuntu_dev create' không? [y/N]: " create_seed_ans
    
    if [[ "$create_seed_ans" =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}>> Đang chạy lệnh tạo ví và tự động lấy Seed...${NC}"
        
        # Chạy lệnh và lưu output vào biến
        # sed 's/\x1b\[[0-9;]*m//g' dùng để lọc bỏ mã màu nếu có, giúp grep chính xác hơn
        RAW_OUTPUT=$(./dfo_miner_ubuntu_dev create)
        
        # In ra màn hình để người dùng vẫn thấy được thông tin gốc
        echo "$RAW_OUTPUT"
        
        # Tự động lọc lấy chuỗi 24 từ (regex: tìm dòng có đúng 24 từ viết thường cách nhau bởi dấu cách)
        AUTO_SEED=$(echo "$RAW_OUTPUT" | grep -oE '\b([a-z]+ ){23}[a-z]+\b' | tail -n 1)

        if [ -n "$AUTO_SEED" ]; then
            echo -e "\n${GREEN}✅ Đã tự động bắt được Seed Phrase:${NC}"
            echo -e "${YELLOW}$AUTO_SEED${NC}"
            MNEMONIC_VAL="$AUTO_SEED"
        else
            echo -e "\n${RED}⚠️  Không tự bắt được seed (do format lạ). Vui lòng copy thủ công.${NC}"
        fi
    fi

    # Nếu không tự bắt được hoặc người dùng chọn không tạo mới thì nhập tay
    while [ -z "$MNEMONIC_VAL" ]; do
        read -p "👉 Nhập MNEMONIC (Copy paste chuỗi 24 từ vào đây): " input_mnemonic
        MNEMONIC_VAL=$(echo "$input_mnemonic" | xargs) # xargs để trim khoảng trắng thừa
    done

    # 1.2 Nhập các tham số khác
    read -p "👉 Nhập AMOUNT_ACCOUNT (Mặc định: 50): " input_amount
    AMOUNT_ACCOUNT=${input_amount:-50}

    read -p "👉 Nhập ACCOUNT_INDEX_START (Mặc định: 1): " input_index
    ACCOUNT_INDEX_START=${input_index:-1}

    read -p "👉 Nhập RUST_THREADS (Mặc định: 10): " input_threads
    RUST_THREADS=${input_threads:-10}

    read -p "👉 Nhập DEFAULT_MAX_SOLVERS (Mặc định: 1): " input_solvers
    DEFAULT_MAX_SOLVERS=${input_solvers:-1}

    read -p "👉 Nhập DESTINATION_WALLET_ADDRESS (Bắt buộc): " input_dest_wallet
    DESTINATION_WALLET_ADDRESS=$input_dest_wallet

    # 1.3 Ghi nội dung vào file .env
    cat <<EOF > .env
#--- BẮT BUỘC ---
MNEMONIC="$MNEMONIC_VAL"

# --- CẤU HÌNH SỐ LƯỢNG VÍ ---
AMOUNT_ACCOUNT=$AMOUNT_ACCOUNT
ACCOUNT_INDEX_START=$ACCOUNT_INDEX_START
# Số luồng CPU dành cho mỗi tiến trình giải
RUST_THREADS=$RUST_THREADS
DEFAULT_MAX_SOLVERS=$DEFAULT_MAX_SOLVERS

# --- CẤU HÌNH DONATE ---
DESTINATION_WALLET_ADDRESS=$DESTINATION_WALLET_ADDRESS
DEV_FEE_PERCENTAGE=5

# Thông điệp ký khi đăng ký
REGISTER_MESSAGE="I agree to abide by the terms and conditions as described in version 1-0 of the Defensio DFO mining process: 2da58cd94d6ccf3d933c4a55ebc720ba03b829b84033b4844aafc36828477cc0"
REGISTRATION_HASH="2da58cd94d6ccf3d933c4a55ebc720ba03b829b84033b4844aafc36828477cc0"
REGISTRATION_VERSION="1-0"
# Tin nhắn Donate (Phần cố định trước địa chỉ ví)
# Night/DFO dùng: "Assign accumulated Scavenger rights to: "
DONATE_MESSAGE_PREFIX="Assign accumulated Scavenger rights to: "

EOF

    echo -e "${GREEN}✅ Đã tạo file .env thành công!${NC}"
else
    echo -e "${BLUE}⏩ Giữ nguyên file .env cũ.${NC}"
fi

# --- BƯỚC 2: ĐĂNG KÝ (REGISTER) ---
print_header "Bước 2: Đăng ký (Register)"
read -p "❓ Bạn có muốn chạy lệnh Đăng ký (Register) không? [y/N]: " reg_ans
if [[ "$reg_ans" =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}>> Đang chạy ./dfo_miner_ubuntu_dev register...${NC}"
    ./dfo_miner_ubuntu_dev register
else
    echo -e "${BLUE}⏩ Bỏ qua bước Register.${NC}"
fi

# --- BƯỚC 3: QUYÊN GÓP (DONATE) ---
print_header "Bước 3: Quyên góp (Donate)"
read -p "❓ Bạn có muốn chạy lệnh Quyên góp (Donate) không? [y/N]: " donate_ans
if [[ "$donate_ans" =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}>> Đang chạy ./dfo_miner_ubuntu_dev donate...${NC}"
    ./dfo_miner_ubuntu_dev donate
else
    echo -e "${BLUE}⏩ Bỏ qua bước Donate.${NC}"
fi

# --- BƯỚC 4: CHẠY MINER (RUN) ---
print_header "Bước 4: Kiểm tra và Chạy Miner"

if [ -f "challenges.json" ]; then
    echo -e "${GREEN}✅ Tìm thấy file challenges.json.${NC}"
    echo -e "${BLUE}🚀 Khởi động Miner chính (./dfo_miner_ubuntu_dev run)...${NC}"
    ./dfo_miner_ubuntu_dev run
else
    echo -e "${RED}❌ Lỗi: Không tìm thấy file 'challenges.json'.${NC}"
    echo -e "${YELLOW}💡 Vui lòng kiểm tra lại quy trình hoặc chạy lại file này để thực hiện bước Register/Donate nếu cần.${NC}"
    exit 1
fi

echo -e "\n${GREEN}✨ Script hoàn tất.${NC}"
