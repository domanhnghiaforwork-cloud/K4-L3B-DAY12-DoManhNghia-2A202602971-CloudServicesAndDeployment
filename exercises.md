# Phiếu Phản Ánh — K4 Level 3B, Ngày 12

> **Bài làm cá nhân.** Trả lời bằng lời của chính bạn, dựa trên những gì bạn
> quan sát được khi chạy code — không sao chép đáp án của người khác.
>
> Cách trả lời: thay dòng đánh dấu câu trả lời còn trống bằng câu trả lời.
> `grade.py` đếm số câu đã trả lời (15 điểm cho 10 câu).
>
> Họ và tên: Đỗ Mạnh Nghĩa  Mã học viên: 2A202602971

---

### Câu 1 — Fail fast (CP1)

Trong `Settings`, `agent_api_key` không có giá trị mặc định nên app chết ngay
khi khởi động nếu thiếu biến môi trường. Hãy mô tả một tình huống cụ thể mà
việc "chết sớm" này cứu bạn, so với việc để mặc định `"changeme"`.

> Nếu quên cấu hình `AGENT_API_KEY` trên môi trường staging, app dừng ngay khi khởi động nên mình phát hiện lỗi cấu hình trong log deploy trước khi nhận traffic. Nếu có mặc định `changeme`, app vẫn chạy và có thể chấp nhận một khóa ai cũng đoán được.

---

### Câu 2 — Log cho máy đọc (CP1)

Chạy service và gọi `/ask` vài lần. Dán một dòng log JSON bạn thu được, rồi
nêu **hai** việc bạn làm được với dòng log đó mà `print("đã trả lời xong")`
không làm được.

> Log JSON lấy từ request thử nghiệm local qua Docker (dùng khóa giả, không phải log production):
>
> ```json
> {"event": "ask_completed", "level": "info", "timestamp": "2026-09-29T16:48:08.400226+00:00", "user_id": "lab-log-check", "tokens_in": 3, "tokens_out": 37, "cost_usd": 2.265e-05}
> ```
>
> Mình có thể lọc và đếm request theo `user_id` để tìm người gọi bất thường, đồng thời tổng hợp `cost_usd` để theo dõi chi phí. Log dạng câu chữ không có các trường thống nhất để lọc và tính toán đáng tin cậy.

---

### Câu 3 — Kích thước image (CP2)

Build cả hai phiên bản và ghi lại số đo thật:

```bash
docker build -f <Dockerfile-1-stage> -t agent:single .
docker build -t agent:multi .
docker images | grep agent
```

| Bản | Dung lượng |
|-----|-----------|
| 1 stage (bản đầu) | 1,727.9 MB |
| Multi-stage | 309.7 MB |

Đây là số đo từ Docker image được build ngày 2026-09-29 (dung lượng Docker báo theo byte, đổi sang MB thập phân). Bản một stage dùng `python:3.11` đầy đủ và giữ cả pip cache; bản multi-stage dùng `python:3.11-slim`, cài dependency ở builder và chỉ chép virtualenv cùng source sang runtime. Phần lớn chênh lệch đến từ base image đầy đủ và dữ liệu build/cache không cần cho runtime.


---

### Câu 4 — Thứ tự lệnh trong Dockerfile (CP2)

Sửa một ký tự trong `app/main.py` rồi build lại. Với Dockerfile của bạn, những
layer nào được dùng lại từ cache, layer nào phải chạy lại? Nếu bạn đặt
`COPY . .` lên trước `RUN pip install` thì kết quả khác thế nào?

> Khi chỉ sửa `app/main.py`, layer cài dependency vẫn được dùng lại vì `requirements.txt` không đổi và lệnh `COPY app/` nằm sau bước cài thư viện. Các layer sau `COPY app/` cần được tạo lại. Nếu `COPY . .` đứng trước `RUN pip install`, mọi thay đổi source làm layer COPY đổi, khiến bước cài dependency chạy lại dù requirements không đổi.

---

### Câu 5 — Vì sao không chạy bằng root (CP2)

Container mặc định chạy bằng root. Mô tả chuỗi sự kiện dẫn từ "một lỗ hổng
trong code Python của bạn" tới "kẻ tấn công có quyền cao trên máy host", và
lệnh `USER` cắt đứt chuỗi đó ở chỗ nào.

> Nếu lỗ hổng cho phép thực thi lệnh tùy ý trong app, lệnh đó chạy với quyền của user trong container. Khi container chạy root, kẻ tấn công có nhiều quyền hơn trên filesystem và các tài nguyên được mount; nếu tiếp tục khai thác cấu hình/container runtime hoặc lỗ hổng kernel để thoát container thì có thể ảnh hưởng tới host. `USER appuser` hạ quyền tiến trình ngay trong container, giảm tác động và cắt đường leo quyền trực tiếp từ quyền root của container; nó không tự loại bỏ mọi khả năng container escape.

---

### Câu 6 — Cửa sổ trượt (CP3)

Rate limit của bạn dùng sliding window 60 giây. Nếu thay bằng cách đếm theo
phút đồng hồ (reset lúc giây 00), một người dùng có thể gửi tối đa bao nhiêu
request trong 2 giây liên tiếp khi hạn mức là 10/phút? Giải thích cách đạt được
con số đó.

> Tối đa 20 request trong 2 giây: gửi 10 request ngay trước lúc phút đồng hồ đổi từ giây 59 sang 00, rồi 10 request ngay sau khi đổi phút. Bộ đếm theo phút lịch đã reset nên cho qua cả hai nhóm, dù sliding window sẽ thấy 20 request trong khoảng 2 giây.

---

### Câu 7 — Rate limit và cost guard (CP3)

Hai cơ chế này khác nhau ở điểm nào? Cho một tình huống mà rate limit cho qua
nhưng cost guard phải chặn, và một tình huống ngược lại.

> Rate limit giới hạn số request trong một khoảng thời gian; cost guard giới hạn tổng tiền của một user trong tháng. Ví dụ một request dùng nhiều token vẫn có thể nằm trong hạn mức 10 request/phút nhưng bị cost guard chặn nếu ngân sách tháng đã hết. Ngược lại, user còn ngân sách nhưng gửi request thứ 11 trong cùng phút sẽ bị rate limit chặn.

---

### Câu 8 — /health khác /ready (CP4)

Nếu gộp hai endpoint làm một và cho nó kiểm tra Redis, chuyện gì xảy ra với cụm
3 container khi Redis mất kết nối 30 giây? Trả lời theo đúng thứ tự sự kiện.

> Khi Redis mất kết nối, probe gộp sẽ thất bại trên cả ba container. Orchestrator hiểu nhầm service đã chết và lần lượt restart các container; container mới vẫn không kết nối được Redis nên probe tiếp tục thất bại, làm cụm restart liên tục và có thể mất toàn bộ capacity. Nếu tách probe, `/health` vẫn 200 nên container không bị restart; `/ready` trả 503 để load balancer tạm ngừng gửi traffic tới instance chưa sẵn sàng. Redis phục hồi thì readiness trở lại 200.

---

### Câu 9 — Stateless (CP4)

Chạy `docker compose up --scale agent=3` rồi gọi `/ask` nhiều lần với cùng một
`X-User-Id`. Quan sát `history_length` trong response. Nếu lịch sử được lưu
trong một dict Python thay vì Redis, bạn sẽ thấy con số đó thay đổi thế nào?

> Mỗi lượt hỏi thêm hai message (user và assistant), nên với Redis dùng chung các giá trị `history_length` kỳ vọng là 0, 2, 4, ... dù request tới instance nào. Nếu dùng dict trong RAM, mỗi instance giữ lịch sử riêng: request luân phiên qua A, B, A có thể trả 0, 0, 2 thay vì 0, 2, 4; restart instance cũng làm mất phần lịch sử trong dict đó.

---

### Câu 10 — Deploy thật (CP5)

Ghi lại **một** lỗi bạn gặp khi deploy lên cloud (build fail, health check
timeout, sai REDIS_URL, app không đọc `$PORT`...): thông báo lỗi là gì, bạn
tìm ra nguyên nhân bằng cách nào, và sửa ra sao?

> Cần Nghĩa bổ sung lỗi deploy thực tế đã gặp, thông báo trong build/runtime log, cách xác định nguyên nhân và cách sửa. Mình không có dữ liệu về lịch sử lỗi trên dashboard Render nên không tự điền một sự cố giả.
