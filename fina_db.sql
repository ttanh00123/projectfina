-- phpMyAdmin SQL Dump
-- version 5.2.3
-- https://www.phpmyadmin.net/
--
-- Máy chủ: mysql
-- Thời gian đã tạo: Th5 27, 2026 lúc 06:00 AM
-- Phiên bản máy phục vụ: 8.0.44
-- Phiên bản PHP: 8.3.28

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Cơ sở dữ liệu: `fina`
--

DELIMITER $$
--
-- Thủ tục
--
CREATE DEFINER=`fina`@`%` PROCEDURE `sp_recalculate_wallet_balance` ()   BEGIN
  UPDATE wallets w
  LEFT JOIN (
    SELECT wallet_id, SUM(CAST(amount AS DECIMAL(15,2))) AS total
    FROM transactions WHERE type = 0 AND status = 0
    GROUP BY wallet_id
  ) expense ON w.id = expense.wallet_id
  LEFT JOIN (
    SELECT wallet_id, SUM(CAST(amount AS DECIMAL(15,2))) AS total
    FROM transactions WHERE type = 1 AND status = 0
    GROUP BY wallet_id
  ) income ON w.id = income.wallet_id
  LEFT JOIN (
    SELECT wallet_id, SUM(CAST(amount AS DECIMAL(15,2))) AS total
    FROM transactions WHERE to_wallet_id IS NOT NULL AND status = 0
    GROUP BY wallet_id
  ) transfer_out ON w.id = transfer_out.wallet_id
  LEFT JOIN (
    SELECT to_wallet_id, SUM(CAST(amount AS DECIMAL(15,2))) AS total
    FROM transactions WHERE to_wallet_id IS NOT NULL AND status = 0
    GROUP BY to_wallet_id
  ) transfer_in ON w.id = transfer_in.to_wallet_id
  SET w.balance = 0.00
    - COALESCE(expense.total, 0)
    + COALESCE(income.total, 0)
    - COALESCE(transfer_out.total, 0)
    + COALESCE(transfer_in.total, 0);
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `bill_images`
--

CREATE TABLE `bill_images` (
  `id` int NOT NULL,
  `transaction_id` int NOT NULL,
  `url` varchar(500) COLLATE utf8mb4_general_ci NOT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `categories`
--

CREATE TABLE `categories` (
  `id` int NOT NULL,
  `userid` int NOT NULL,
  `name` varchar(100) COLLATE utf8mb4_general_ci NOT NULL,
  `icon` varchar(100) COLLATE utf8mb4_general_ci NOT NULL,
  `type` tinyint NOT NULL COMMENT '0=expense, 1=income, 2=both',
  `sort_order` int DEFAULT '0',
  `master_id` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Đang đổ dữ liệu cho bảng `categories`
--

INSERT INTO `categories` (`id`, `userid`, `name`, `icon`, `type`, `sort_order`, `master_id`) VALUES
(1, 11, 'Ăn uống', 'restaurant', 0, 1, 9),
(2, 11, 'Đi lại', 'directions_car', 0, 2, 10),
(3, 11, 'Điện thoại', 'phone_android', 0, 3, 11),
(4, 11, 'Internet', 'wifi', 0, 4, 12),
(5, 11, 'Xăng dầu', 'local_gas_station', 0, 5, 13),
(6, 11, 'Nhu yếu phẩm', 'shopping_basket', 0, 6, 14),
(7, 11, 'Trang phục', 'checkroom', 0, 7, 15),
(8, 11, 'Làm đẹp', 'face', 0, 8, 16),
(9, 11, 'Giải trí', 'movie', 0, 9, 17),
(10, 11, 'Du lịch', 'flight', 0, 10, 18),
(11, 11, 'Chu cấp', 'family_restroom', 0, 11, 19),
(12, 11, 'Hiếu hỉ', 'celebration', 0, 12, 20),
(13, 11, 'Khám bệnh', 'local_hospital', 0, 13, 21),
(14, 11, 'Thuốc men', 'medication', 0, 14, 22),
(15, 11, 'Tập luyện', 'fitness_center', 0, 15, 23),
(16, 11, 'Quỹ', 'savings', 0, 16, 24),
(17, 11, 'Sửa chữa', 'build', 0, 17, 25),
(18, 11, 'Tai nạn', 'car_crash', 0, 18, 26),
(19, 11, 'Phí phạt', 'gavel', 0, 19, 27),
(20, 11, 'Tiền nhà', 'home', 0, 20, 28),
(21, 11, 'Tiền điện', 'bolt', 0, 21, 29),
(22, 11, 'Tiền nước', 'water_drop', 0, 22, 30),
(23, 11, 'Học phí', 'school', 0, 23, 31),
(24, 11, 'Bảo hiểm', 'security', 0, 24, 32),
(25, 11, 'Trả góp', 'credit_score', 0, 25, 33),
(26, 11, 'Khác', 'other', 0, 26, 34),
(27, 11, 'Lương', 'payments', 1, 1, 1),
(28, 11, 'Thưởng', 'card_giftcard', 1, 2, 2),
(29, 11, 'Phụ cấp', 'volunteer_activism', 1, 3, 3),
(30, 11, 'Kinh doanh', 'storefront', 1, 4, 4),
(31, 11, 'Đầu tư', 'trending_up', 1, 5, 5),
(32, 11, 'Thu nhập thụ động', 'auto_awesome', 1, 6, 6),
(33, 11, 'Quà tặng', 'redeem', 1, 7, 7),
(34, 11, 'Thu khác', 'add_circle_outline', 1, 8, 8),
(35, 11, 'Khác', 'other', 1, 27, 35),
(36, 19, 'Ăn uống', 'restaurant', 0, 1, 9),
(37, 19, 'Đi lại', 'directions_car', 0, 2, 10),
(38, 19, 'Điện thoại', 'phone_android', 0, 3, 11),
(39, 19, 'Internet', 'wifi', 0, 4, 12),
(40, 19, 'Xăng dầu', 'local_gas_station', 0, 5, 13),
(41, 19, 'Nhu yếu phẩm', 'shopping_basket', 0, 6, 14),
(42, 19, 'Trang phục', 'checkroom', 0, 7, 15),
(43, 19, 'Làm đẹp', 'face', 0, 8, 16),
(44, 19, 'Giải trí', 'movie', 0, 9, 17),
(45, 19, 'Du lịch', 'flight', 0, 10, 18),
(46, 19, 'Chu cấp', 'family_restroom', 0, 11, 19),
(47, 19, 'Hiếu hỉ', 'celebration', 0, 12, 20),
(48, 19, 'Khám bệnh', 'local_hospital', 0, 13, 21),
(49, 19, 'Thuốc men', 'medication', 0, 14, 22),
(50, 19, 'Tập luyện', 'fitness_center', 0, 15, 23),
(51, 19, 'Quỹ', 'savings', 0, 16, 24),
(52, 19, 'Sửa chữa', 'build', 0, 17, 25),
(53, 19, 'Tai nạn', 'car_crash', 0, 18, 26),
(54, 19, 'Phí phạt', 'gavel', 0, 19, 27),
(55, 19, 'Tiền nhà', 'home', 0, 20, 28),
(56, 19, 'Tiền điện', 'bolt', 0, 21, 29),
(57, 19, 'Tiền nước', 'water_drop', 0, 22, 30),
(58, 19, 'Học phí', 'school', 0, 23, 31),
(59, 19, 'Bảo hiểm', 'security', 0, 24, 32),
(60, 19, 'Trả góp', 'credit_score', 0, 25, 33),
(61, 19, 'Khác', 'other', 0, 26, 34),
(62, 19, 'Lương', 'payments', 1, 1, 1),
(63, 19, 'Thưởng', 'card_giftcard', 1, 2, 2),
(64, 19, 'Phụ cấp', 'volunteer_activism', 1, 3, 3),
(65, 19, 'Kinh doanh', 'storefront', 1, 4, 4),
(66, 19, 'Đầu tư', 'trending_up', 1, 5, 5),
(67, 19, 'Thu nhập thụ động', 'auto_awesome', 1, 6, 6),
(68, 19, 'Quà tặng', 'redeem', 1, 7, 7),
(69, 19, 'Thu khác', 'add_circle_outline', 1, 8, 8),
(70, 19, 'Khác', 'other', 1, 27, 35),
(71, 20, 'Ăn uống', 'restaurant', 0, 1, 9),
(72, 20, 'Đi lại', 'directions_car', 0, 2, 10),
(73, 20, 'Điện thoại', 'phone_android', 0, 3, 11),
(74, 20, 'Internet', 'wifi', 0, 4, 12),
(75, 20, 'Xăng dầu', 'local_gas_station', 0, 5, 13),
(76, 20, 'Nhu yếu phẩm', 'shopping_basket', 0, 6, 14),
(77, 20, 'Trang phục', 'checkroom', 0, 7, 15),
(78, 20, 'Làm đẹp', 'face', 0, 8, 16),
(79, 20, 'Giải trí', 'movie', 0, 9, 17),
(80, 20, 'Du lịch', 'flight', 0, 10, 18),
(81, 20, 'Chu cấp', 'family_restroom', 0, 11, 19),
(82, 20, 'Hiếu hỉ', 'celebration', 0, 12, 20),
(83, 20, 'Khám bệnh', 'local_hospital', 0, 13, 21),
(84, 20, 'Thuốc men', 'medication', 0, 14, 22),
(85, 20, 'Tập luyện', 'fitness_center', 0, 15, 23),
(86, 20, 'Quỹ', 'savings', 0, 16, 24),
(87, 20, 'Sửa chữa', 'build', 0, 17, 25),
(88, 20, 'Tai nạn', 'car_crash', 0, 18, 26),
(89, 20, 'Phí phạt', 'gavel', 0, 19, 27),
(90, 20, 'Tiền nhà', 'home', 0, 20, 28),
(91, 20, 'Tiền điện', 'bolt', 0, 21, 29),
(92, 20, 'Tiền nước', 'water_drop', 0, 22, 30),
(93, 20, 'Học phí', 'school', 0, 23, 31),
(94, 20, 'Bảo hiểm', 'security', 0, 24, 32),
(95, 20, 'Trả góp', 'credit_score', 0, 25, 33),
(96, 20, 'Khác', 'other', 0, 26, 34),
(97, 20, 'Lương', 'payments', 1, 1, 1),
(98, 20, 'Thưởng', 'card_giftcard', 1, 2, 2),
(99, 20, 'Phụ cấp', 'volunteer_activism', 1, 3, 3),
(100, 20, 'Kinh doanh', 'storefront', 1, 4, 4),
(101, 20, 'Đầu tư', 'trending_up', 1, 5, 5),
(102, 20, 'Thu nhập thụ động', 'auto_awesome', 1, 6, 6),
(103, 20, 'Quà tặng', 'redeem', 1, 7, 7),
(104, 20, 'Thu khác', 'add_circle_outline', 1, 8, 8),
(105, 20, 'Khác', 'other', 1, 27, 35);

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `debt_tracking`
--

CREATE TABLE `debt_tracking` (
  `id` int NOT NULL,
  `userid` int NOT NULL,
  `name` varchar(100) COLLATE utf8mb4_general_ci NOT NULL,
  `amount` decimal(18,2) NOT NULL,
  `type` tinyint NOT NULL COMMENT '0=owe,1=lend',
  `due_date` date DEFAULT NULL,
  `notes` text COLLATE utf8mb4_general_ci,
  `status` tinyint DEFAULT '0',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `master_categories`
--

CREATE TABLE `master_categories` (
  `id` int NOT NULL,
  `icon` varchar(100) COLLATE utf8mb4_general_ci NOT NULL,
  `type` tinyint NOT NULL COMMENT '0=expense, 1=income',
  `sort_order` int DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Đang đổ dữ liệu cho bảng `master_categories`
--

INSERT INTO `master_categories` (`id`, `icon`, `type`, `sort_order`) VALUES
(1, 'payments', 1, 1),
(2, 'card_giftcard', 1, 2),
(3, 'volunteer_activism', 1, 3),
(4, 'storefront', 1, 4),
(5, 'trending_up', 1, 5),
(6, 'auto_awesome', 1, 6),
(7, 'redeem', 1, 7),
(8, 'add_circle_outline', 1, 8),
(9, 'restaurant', 0, 1),
(10, 'directions_car', 0, 2),
(11, 'phone_android', 0, 3),
(12, 'wifi', 0, 4),
(13, 'local_gas_station', 0, 5),
(14, 'shopping_basket', 0, 6),
(15, 'checkroom', 0, 7),
(16, 'face', 0, 8),
(17, 'movie', 0, 9),
(18, 'flight', 0, 10),
(19, 'family_restroom', 0, 11),
(20, 'celebration', 0, 12),
(21, 'local_hospital', 0, 13),
(22, 'medication', 0, 14),
(23, 'fitness_center', 0, 15),
(24, 'savings', 0, 16),
(25, 'build', 0, 17),
(26, 'car_crash', 0, 18),
(27, 'gavel', 0, 19),
(28, 'home', 0, 20),
(29, 'bolt', 0, 21),
(30, 'water_drop', 0, 22),
(31, 'school', 0, 23),
(32, 'security', 0, 24),
(33, 'credit_score', 0, 25),
(34, 'other', 0, 26),
(35, 'other', 1, 27);

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `master_category_translations`
--

CREATE TABLE `master_category_translations` (
  `id` int NOT NULL,
  `category_id` int NOT NULL,
  `locale` varchar(10) COLLATE utf8mb4_general_ci NOT NULL,
  `name` varchar(100) COLLATE utf8mb4_general_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Đang đổ dữ liệu cho bảng `master_category_translations`
--

INSERT INTO `master_category_translations` (`id`, `category_id`, `locale`, `name`) VALUES
(1, 1, 'vi', 'Lương'),
(2, 1, 'en', 'Salary'),
(3, 2, 'vi', 'Thưởng'),
(4, 2, 'en', 'Bonus'),
(5, 3, 'vi', 'Phụ cấp'),
(6, 3, 'en', 'Allowance'),
(7, 4, 'vi', 'Kinh doanh'),
(8, 4, 'en', 'Business'),
(9, 5, 'vi', 'Đầu tư'),
(10, 5, 'en', 'Investment'),
(11, 6, 'vi', 'Thu nhập thụ động'),
(12, 6, 'en', 'Passive Income'),
(13, 7, 'vi', 'Quà tặng'),
(14, 7, 'en', 'Gift'),
(15, 8, 'vi', 'Thu khác'),
(16, 8, 'en', 'Other Income'),
(17, 9, 'vi', 'Ăn uống'),
(18, 9, 'en', 'Food & Drink'),
(19, 10, 'vi', 'Đi lại'),
(20, 10, 'en', 'Transport'),
(21, 11, 'vi', 'Điện thoại'),
(22, 11, 'en', 'Phone'),
(23, 12, 'vi', 'Internet'),
(24, 12, 'en', 'Internet'),
(25, 13, 'vi', 'Xăng dầu'),
(26, 13, 'en', 'Fuel'),
(27, 14, 'vi', 'Nhu yếu phẩm'),
(28, 14, 'en', 'Groceries'),
(29, 15, 'vi', 'Trang phục'),
(30, 15, 'en', 'Clothing'),
(31, 16, 'vi', 'Làm đẹp'),
(32, 16, 'en', 'Beauty'),
(33, 17, 'vi', 'Giải trí'),
(34, 17, 'en', 'Entertainment'),
(35, 18, 'vi', 'Du lịch'),
(36, 18, 'en', 'Travel'),
(37, 19, 'vi', 'Chu cấp'),
(38, 19, 'en', 'Family Support'),
(39, 20, 'vi', 'Hiếu hỉ'),
(40, 20, 'en', 'Events & Gifts'),
(41, 21, 'vi', 'Khám bệnh'),
(42, 21, 'en', 'Medical'),
(43, 22, 'vi', 'Thuốc men'),
(44, 22, 'en', 'Medicine'),
(45, 23, 'vi', 'Tập luyện'),
(46, 23, 'en', 'Fitness'),
(47, 24, 'vi', 'Quỹ'),
(48, 24, 'en', 'Fund'),
(49, 25, 'vi', 'Sửa chữa'),
(50, 25, 'en', 'Repair'),
(51, 26, 'vi', 'Tai nạn'),
(52, 26, 'en', 'Accident'),
(53, 27, 'vi', 'Phí phạt'),
(54, 27, 'en', 'Fine & Fee'),
(55, 28, 'vi', 'Tiền nhà'),
(56, 28, 'en', 'Rent'),
(57, 29, 'vi', 'Tiền điện'),
(58, 29, 'en', 'Electricity'),
(59, 30, 'vi', 'Tiền nước'),
(60, 30, 'en', 'Water'),
(61, 31, 'vi', 'Học phí'),
(62, 31, 'en', 'Education'),
(63, 32, 'vi', 'Bảo hiểm'),
(64, 32, 'en', 'Insurance'),
(65, 33, 'vi', 'Trả góp'),
(66, 33, 'en', 'Installment'),
(67, 34, 'en', 'Other'),
(68, 35, 'en', 'Other'),
(69, 34, 'vi', 'Khác'),
(70, 35, 'vi', 'Khác');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `pending_inputs`
--

CREATE TABLE `pending_inputs` (
  `id` int NOT NULL,
  `userid` int NOT NULL,
  `raw_text` text COLLATE utf8mb4_general_ci,
  `status` tinyint DEFAULT '0',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `recurring_schedules`
--

CREATE TABLE `recurring_schedules` (
  `id` int NOT NULL,
  `template_id` int NOT NULL,
  `next_run` datetime NOT NULL,
  `frequency` varchar(20) COLLATE utf8mb4_general_ci DEFAULT 'monthly',
  `status` tinyint DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `recurring_templates`
--

CREATE TABLE `recurring_templates` (
  `id` int NOT NULL,
  `userid` int NOT NULL,
  `name` varchar(100) COLLATE utf8mb4_general_ci NOT NULL,
  `amount` decimal(18,2) NOT NULL,
  `type` tinyint NOT NULL,
  `category_id` int DEFAULT NULL,
  `wallet_id` int DEFAULT NULL,
  `notes` text COLLATE utf8mb4_general_ci,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `transactions`
--

CREATE TABLE `transactions` (
  `id` int NOT NULL,
  `userid` int NOT NULL,
  `content` text COLLATE utf8mb4_general_ci,
  `currency` varchar(10) COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'VND',
  `amount` decimal(18,2) NOT NULL,
  `type` tinyint NOT NULL COMMENT '0=expense,1=income,2=transfer',
  `date_time` datetime NOT NULL,
  `category_id` int DEFAULT NULL,
  `debt_id` int DEFAULT NULL,
  `notes` text COLLATE utf8mb4_general_ci,
  `recurring_id` int DEFAULT NULL,
  `wallet_id` int NOT NULL,
  `to_wallet_id` int DEFAULT NULL,
  `receive_amount` decimal(18,2) DEFAULT NULL,
  `bill_image` varchar(500) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `tags` varchar(500) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `status` tinyint DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Đang đổ dữ liệu cho bảng `transactions`
--

INSERT INTO `transactions` (`id`, `userid`, `content`, `currency`, `amount`, `type`, `date_time`, `category_id`, `debt_id`, `notes`, `recurring_id`, `wallet_id`, `to_wallet_id`, `receive_amount`, `bill_image`, `tags`, `status`) VALUES
(28, 1, 'Vé Pháo hoa Đà Nẵng 2026', 'VND', 3080000.00, 0, '2026-05-19 15:25:49', 18, NULL, NULL, NULL, 2, NULL, NULL, NULL, NULL, 0),
(29, 1, 'Book phòng Ancient Retreat Hội An x 2 đêm', 'VND', 3387458.00, 0, '2026-05-19 15:29:08', 18, NULL, 'Ngày 11-13/6/2026', NULL, 4, NULL, NULL, NULL, NULL, 0),
(30, 1, 'mua đồ shopee đi phượt', 'VND', 104000.00, 0, '2026-05-20 00:00:00', 18, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, 0),
(31, 1, 'Bà Nà Hills', 'VND', 5050000.00, 0, '2026-05-21 00:00:00', 18, NULL, 'vé bà nà x 4 ng', NULL, 1, NULL, NULL, NULL, NULL, 0),
(32, 1, 'Đá Nàng', 'VND', 800000.00, 0, '2026-05-21 00:00:00', 28, NULL, '1 đêm ở Đà Nẵng 13/6/2026', NULL, 1, NULL, NULL, NULL, NULL, 0),
(35, 1, 'thuê ks Đà Nẵng ngày 13/6', 'VND', 800000.00, 0, '2026-05-21 09:01:44', 28, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, 0),
(38, 1, NULL, 'VND', 800000.00, 0, '2026-05-19 10:00:00', 28, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, 0),
(39, 1, 'Mua dụng cụ đi phượt', 'VND', 500000.00, 0, '2026-05-23 03:43:09', 14, NULL, 'Phượt 2026', NULL, 1, NULL, NULL, NULL, NULL, 0),
(41, 1, 'Đặt cọc Khách sạn Sunrise Thiên Cầm', 'VND', 500000.00, 0, '2026-05-24 23:00:00', 18, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, 0);

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `users`
--

CREATE TABLE `users` (
  `id` int NOT NULL,
  `email` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `password_hash` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'bcrypt-sha256 hash',
  `display_name` varchar(100) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `provider` varchar(50) COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'local',
  `provider_id` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `otp_code` varchar(10) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `otp_expires_at` datetime DEFAULT NULL,
  `birth_date` date DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `gender` tinyint DEFAULT NULL,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `address` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `fcm_token` text COLLATE utf8mb4_general_ci,
  `avatar` varchar(500) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `status` tinyint DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Đang đổ dữ liệu cho bảng `users`
--

INSERT INTO `users` (`id`, `email`, `password_hash`, `display_name`, `provider`, `provider_id`, `otp_code`, `otp_expires_at`, `birth_date`, `created_at`, `gender`, `updated_at`, `address`, `fcm_token`, `avatar`, `status`) VALUES
(1, 'trantrung22@gmail.com', '$bcrypt-sha256$v=2,t=2b,r=12$10.eXUtagixlYq.FgVdo.O$5gg195ldrTzeB1YgIRk4rkPBg5NRogG', 'Trần Trung', 'local', NULL, NULL, NULL, NULL, '2026-04-26 04:42:15', NULL, '2026-04-26 11:16:11', NULL, NULL, NULL, 9);

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `user_master_data_hash`
--

CREATE TABLE `user_master_data_hash` (
  `userid` int NOT NULL,
  `md5_hash` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Đang đổ dữ liệu cho bảng `user_master_data_hash`
--

INSERT INTO `user_master_data_hash` (`userid`, `md5_hash`, `updated_at`) VALUES
(1, '206db8a96fe3f77c8067c1a5459ccdd9', '2026-05-27 12:42:18');

-- --------------------------------------------------------

--
-- Cấu trúc đóng vai cho view `v_transaction_summary`
-- (See below for the actual view)
--
CREATE TABLE `v_transaction_summary` (
`currency` varchar(10)
,`month` varchar(7)
,`quarter` int
,`status` tinyint
,`total` decimal(15,2)
,`type` tinyint
,`userid` int
,`year` varchar(4)
);

-- --------------------------------------------------------

--
-- Cấu trúc đóng vai cho view `v_user_balance`
-- (See below for the actual view)
--
CREATE TABLE `v_user_balance` (
`currency` varchar(10)
,`total_balance` decimal(37,2)
,`userid` int
);

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `wallets`
--

CREATE TABLE `wallets` (
  `id` int NOT NULL,
  `userid` int NOT NULL,
  `name` varchar(100) COLLATE utf8mb4_general_ci NOT NULL,
  `wallet_type` varchar(50) COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'wallet_type.cash',
  `currency` varchar(10) COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'VND',
  `balance` decimal(18,2) NOT NULL DEFAULT '0.00',
  `account_number` varchar(50) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `description` text COLLATE utf8mb4_general_ci,
  `credit_limit` decimal(18,2) DEFAULT NULL,
  `sort_order` int DEFAULT '0',
  `color` varchar(20) COLLATE utf8mb4_general_ci DEFAULT '#1D9E75',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `status` tinyint DEFAULT '1',
  `is_deleted` tinyint DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Đang đổ dữ liệu cho bảng `wallets`
--

INSERT INTO `wallets` (`id`, `userid`, `name`, `wallet_type`, `currency`, `balance`, `account_number`, `description`, `credit_limit`, `sort_order`, `color`, `created_at`, `status`, `is_deleted`) VALUES
(1, 1, 'Tiền mặt', 'wallet_type.cash', 'VND', -8554000.00, NULL, NULL, NULL, 1, '#1D9E75', '2026-04-26 04:42:19', 1, 0),
(2, 1, 'Vietcombank', 'wallet_type.bank', 'VND', -3080000.00, '2981', NULL, NULL, 2, '#888780', '2026-04-26 11:14:01', 1, 0),
(3, 1, 'Sacombank', 'wallet_type.credit', 'VND', 0.00, '9538', NULL, NULL, 3, '#1D9E75', '2026-04-26 11:18:52', 1, 10),
(4, 1, 'VP Bank Neo', 'wallet_type.credit', 'VND', -3387458.00, '4009', NULL, 0.00, 4, '#378ADD', '2026-04-26 11:21:00', 1, 10);

--
-- Chỉ mục cho các bảng đã đổ
--

--
-- Chỉ mục cho bảng `bill_images`
--
ALTER TABLE `bill_images`
  ADD PRIMARY KEY (`id`);

--
-- Chỉ mục cho bảng `categories`
--
ALTER TABLE `categories`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_categories_user` (`userid`);

--
-- Chỉ mục cho bảng `debt_tracking`
--
ALTER TABLE `debt_tracking`
  ADD PRIMARY KEY (`id`);

--
-- Chỉ mục cho bảng `master_categories`
--
ALTER TABLE `master_categories`
  ADD PRIMARY KEY (`id`);

--
-- Chỉ mục cho bảng `master_category_translations`
--
ALTER TABLE `master_category_translations`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_cat_locale` (`category_id`,`locale`);

--
-- Chỉ mục cho bảng `pending_inputs`
--
ALTER TABLE `pending_inputs`
  ADD PRIMARY KEY (`id`);

--
-- Chỉ mục cho bảng `recurring_schedules`
--
ALTER TABLE `recurring_schedules`
  ADD PRIMARY KEY (`id`);

--
-- Chỉ mục cho bảng `recurring_templates`
--
ALTER TABLE `recurring_templates`
  ADD PRIMARY KEY (`id`);

--
-- Chỉ mục cho bảng `transactions`
--
ALTER TABLE `transactions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_txn_user` (`userid`,`date_time`),
  ADD KEY `idx_txn_wallet` (`wallet_id`),
  ADD KEY `idx_txn_category` (`category_id`);

--
-- Chỉ mục cho bảng `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`),
  ADD KEY `idx_users_email` (`email`);

--
-- Chỉ mục cho bảng `user_master_data_hash`
--
ALTER TABLE `user_master_data_hash`
  ADD PRIMARY KEY (`userid`);

--
-- Chỉ mục cho bảng `wallets`
--
ALTER TABLE `wallets`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_wallets_userid` (`userid`);

--
-- AUTO_INCREMENT cho các bảng đã đổ
--

--
-- AUTO_INCREMENT cho bảng `bill_images`
--
ALTER TABLE `bill_images`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT cho bảng `categories`
--
ALTER TABLE `categories`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=106;

--
-- AUTO_INCREMENT cho bảng `debt_tracking`
--
ALTER TABLE `debt_tracking`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT cho bảng `master_categories`
--
ALTER TABLE `master_categories`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=36;

--
-- AUTO_INCREMENT cho bảng `master_category_translations`
--
ALTER TABLE `master_category_translations`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=71;

--
-- AUTO_INCREMENT cho bảng `pending_inputs`
--
ALTER TABLE `pending_inputs`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT cho bảng `recurring_schedules`
--
ALTER TABLE `recurring_schedules`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT cho bảng `recurring_templates`
--
ALTER TABLE `recurring_templates`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT cho bảng `transactions`
--
ALTER TABLE `transactions`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=42;

--
-- AUTO_INCREMENT cho bảng `users`
--
ALTER TABLE `users`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=21;

--
-- AUTO_INCREMENT cho bảng `wallets`
--
ALTER TABLE `wallets`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

-- --------------------------------------------------------

--
-- Cấu trúc cho view `v_transaction_summary`
--
DROP TABLE IF EXISTS `v_transaction_summary`;

CREATE ALGORITHM=UNDEFINED DEFINER=`fina`@`%` SQL SECURITY DEFINER VIEW `v_transaction_summary`  AS SELECT `transactions`.`userid` AS `userid`, `transactions`.`type` AS `type`, `transactions`.`currency` AS `currency`, cast(`transactions`.`amount` as decimal(15,2)) AS `total`, date_format(`transactions`.`date_time`,'%Y-%m') AS `month`, quarter(`transactions`.`date_time`) AS `quarter`, date_format(`transactions`.`date_time`,'%Y') AS `year`, `transactions`.`status` AS `status` FROM `transactions` WHERE (`transactions`.`status` = 0) ;

-- --------------------------------------------------------

--
-- Cấu trúc cho view `v_user_balance`
--
DROP TABLE IF EXISTS `v_user_balance`;

CREATE ALGORITHM=UNDEFINED DEFINER=`fina`@`%` SQL SECURITY DEFINER VIEW `v_user_balance`  AS SELECT `wallets`.`userid` AS `userid`, `wallets`.`currency` AS `currency`, sum(cast(`wallets`.`balance` as decimal(15,2))) AS `total_balance` FROM `wallets` GROUP BY `wallets`.`userid`, `wallets`.`currency` ;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
