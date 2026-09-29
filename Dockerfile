FROM python:3.11-slim AS builder`
#   [ ] Base image slim (hoặc alpine), không dùng `python:3.11` bản đầy đủ
#   [ ] COPY requirements.txt và pip install TRƯỚC khi COPY source code
#       (Docker cache theo layer: sửa 1 dòng code không phải cài lại thư viện)
#   [ ] Tạo user thường và chuyển sang bằng lệnh `USER` — container chạy
#       root nghĩa là ai thoát được khỏi app cũng thành root trên host
#   [ ] Có `HEALTHCHECK` gọi vào endpoint /health
#   [ ] Đọc cổng từ biến môi trường PORT (cloud tự gán cổng, không cố định 8000)
#
# Kiểm tra:  pytest tests/test_cp2.py -v
# Build thử: docker build -t day12-agent:prod .
#            docker images day12-agent:prod     # xem dung lượng
# ═══════════════════════════════════════════════════════════════════

FROM python:3.11-slim AS builder

WORKDIR /app
ENV VIRTUAL_ENV=/opt/venv
RUN python -m venv "$VIRTUAL_ENV"
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

FROM python:3.11-slim

ENV VIRTUAL_ENV=/opt/venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
WORKDIR /app
COPY --from=builder /opt/venv /opt/venv
COPY app/ ./app/
COPY utils/ ./utils/
RUN useradd --system --create-home appuser && chown -R appuser:appuser /app
USER appuser
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s CMD python -c "import os, urllib.request; urllib.request.urlopen('http://127.0.0.1:' + os.getenv('PORT', '8000') + '/health', timeout=3)" || exit 1
CMD ["sh", "-c", "exec uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
