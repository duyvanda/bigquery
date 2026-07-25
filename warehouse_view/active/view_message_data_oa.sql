CREATE VIEW `spatial-vision-343005.warehouse.view_message_data_oa`
AS SELECT
-- a.id,
a.message_id,
-- a.quote_msg_id,
-- a.src,
a.sender,
a.time,
a.reply_time,
a.type,
-- a.id_order,
-- a.send_type,
-- a.order_status,
-- a.reply_type,
-- a.reply_message,
a.message,
CASE 
  -- 1. Ưu tiên Rule khớp chính xác (không phân biệt hoa thường)
  WHEN LOWER(a.message) IN (
    'hoá đơn, hợp đồng, hồ sơ khách hàng',
    'thông tin sản phẩm, chương trình khuyến mãi & đơn hàng',
    'hướng dẫn đặt hàng online, trình dược viên phụ trách',
    'thông tin khác',
    'đổi date, giao nhận, thanh toán'
  ) THEN a.message

  -- 2. Phân loại theo từ khóa dựa trên sender là customer
  WHEN LOWER(a.sender) = 'customer' THEN
    CASE
      -- Nhóm: Thông tin sản phẩm, Chương trình khuyến mãi & Đơn hàng
      WHEN REGEXP_CONTAINS(LOWER(a.message), r'sản phẩm|xisat|osla|lá đôi|ebysta|vadikiddy|online|metodex|shema|meseca|medoral|metobra|scofi|merika|benita xylo|xypenat|poema|mã sản phẩm|sku|quy cách|danh mục|hàm lượng|dạng bào chế|thành phần|công dụng|hạn dùng|bảo quản|tồn kho|còn hàng|hết hàng|giấy công bố|đơn hàng|đặt hàng|tạo đơn|mã đơn|trạng thái đơn|đơn đã duyệt|đơn chờ xử lý|hủy đơn|sửa đơn|lịch sử đơn hàng|giá bán|giá sỉ|giá lẻ|chiết khấu|khuyến mãi|ctkm|chương trình km|ctr km|combo|tích lũy|thưởng doanh số|ưu đãi|điều kiện áp dụng') 
        THEN 'Thông tin sản phẩm, Chương trình khuyến mãi & Đơn hàng'

      -- Nhóm: Hướng dẫn đặt hàng online, Trình dược viên phụ trách
      WHEN REGEXP_CONTAINS(LOWER(a.message), r'đặt hàng online|đặt hàng trên app|đặt hàng trên app web|cách đặt hàng|hướng dẫn đặt hàng|không đặt được đơn|lỗi đặt hàng|submit đơn|giỏ hàng|checkout|đăng nhập|đăng ký|mật khẩu|tài khoản|trình dược viên|tdv|trình dược|trình|sales phụ trách|nvkd|người phụ trách|đổi tdv|liên hệ tdv|tdv khu vực|ai phụ trách tôi|thông tin sales') 
        THEN 'Hướng dẫn đặt hàng online, Trình dược viên phụ trách'

      -- Nhóm: Hoá đơn, Hợp đồng, Hồ sơ khách hàng
      WHEN REGEXP_CONTAINS(LOWER(a.message), r'hoá đơn|vat|xuất hoá đơn|hoá đơn điện tử|tải hoá đơn|sai thông tin hoá đơn|điều chỉnh hoá đơn|hợp đồng|hđmb|thỏa thuận|ký hợp đồng|ký số|gia hạn hợp đồng|chấm dứt hợp đồng|hồ sơ khách hàng|hồ sơ pháp lý|thông tin nhà thuốc|giấy phép kinh doanh|gpp|mst|cccd|cập nhật hồ sơ|xác thực tài khoản|định danh|chủ hộ kinh doanh|đổi thông tin') 
        THEN 'Hoá đơn, Hợp đồng, Hồ sơ khách hàng'

      -- Nhóm: Đổi date, Giao nhận, Thanh toán
      WHEN REGEXP_CONTAINS(LOWER(a.message), r'đổi date|đổi hạn dùng|hàng cận date|trả hàng|đổi trả|hoàn hàng|giao hàng|giao thuốc|vận chuyển|ship|thời gian giao hàng|chậm giao|chưa nhận hàng|sai hàng|thiếu hàng|biên bản giao nhận|thanh toán|công nợ|hạn thanh toán|quá hạn|chuyển khoản|tiền mặt|đối soát|xác nhận thanh toán|sao kê') 
        THEN 'Đổi date, Giao nhận, Thanh toán'

      -- Nhóm: Khác
      WHEN REGEXP_CONTAINS(LOWER(a.message), r'đăng nhập|quên mật khẩu|lỗi hệ thống|không vào được app|reset mật khẩu|phân quyền|tài khoản bị khóa|hỗ trợ|khiếu nại|phản ánh|góp ý|yêu cầu hỗ trợ|cskh|hotline|thông báo|chính sách|quy định|cập nhật mới|hỏi thông tin chung|kết quả|điểm|hạng|game|minigame|trò chơi|quà|tặng lịch|dk sunohada') 
        THEN 'Thông tin khác'
      
      ELSE 'Chưa mapping'
    END

  -- Mặc định cho sender không phải customer hoặc không khớp gì
  ELSE 'Chưa mapping' 
END AS message_category,
a.dumb_message,
-- a.links,
-- a.thumb,
-- a.url,
-- a.template_html,
a.description,
-- a.attachments,
-- a.from_id,
-- a.to_id,
-- a.user_send,
a.from_display_name,
-- a.from_avatar,
a.to_display_name,
-- a.to_avatar,
-- a.location,
a.is_view,
a.date_view,
a.created_at,
a.updated_at,
-- a.user_feedback_code,
a.customer_code,
a.customer_name,
a.inserted_at,
b.statedescr,
b.territorydescr,
b.channel,
b.classid,
b.shoptype
FROM `spatial-vision-343005.staging.message_data_oa` a
LEFT JOIN `spatial-vision-343005.staging.d_master_khachhang` b ON a.customer_code = b.custid;