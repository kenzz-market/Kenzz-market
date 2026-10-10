# Kenzz Store — Final Fixes Applied

Versi ini memperbaiki alur checkout, stok, voucher, keamanan RPC, RLS, pending purchase, dan beberapa titik XSS.

## Perbaikan utama

- Checkout produk biasa, promo, cart, dan Flash Sale memakai transaksi server-side `create_purchase_order()`.
- Harga, nama, gambar, tipe produk, dan stok final selalu diambil dari database; data harga dari browser tidak dipercaya.
- Pengurangan stok + voucher + pembuatan `purchase_history` terjadi dalam satu transaksi dan otomatis rollback jika salah satu tahap gagal.
- RPC stok lama dinonaktifkan untuk `PUBLIC`, `anon`, dan `authenticated`.
- Direct INSERT ke `purchase_history` dari browser dinonaktifkan.
- Pemakaian voucher dilakukan atomik ketika order benar-benar dibuat; fungsi increment voucher lama dinonaktifkan.
- Flash Sale memakai jalur transaksi yang sama dengan checkout biasa.
- Pending purchase setelah register/Google/OTP sekarang dilanjutkan melalui checkout server-side, bukan mengurangi stok secara terpisah.
- Pending purchase kedaluwarsa setelah 24 jam.
- Referral hanya dapat ditetapkan sekali dan penghitung referral dilindungi dari race condition.
- `member_referrals` tidak lagi terbuka untuk pembacaan publik.
- Produk: publik hanya SELECT; mutasi produk hanya owner melalui RLS.
- Status order dibatasi ke status yang digunakan aplikasi dan perubahan status hanya melalui RPC server-side; owner tidak mendapat UPDATE langsung pada purchase_history.
- Output database yang dirender ke HTML pada area utama sudah di-escape; URL gambar dibatasi ke HTTP/HTTPS.
- JSON object tidak lagi disisipkan mentah ke atribut `onclick` pada katalog/owner/admin.
- Review publik tidak lagi mengambil `user_id` ke browser.
- Validasi client-side dan server-side untuk quantity checkout.
- Pemeriksaan sintaks JavaScript untuk semua file HTML inline: lulus.
- Pemeriksaan sintaks `supabase.js`, `mega-features.js`, `getStats_kenzz.js`, dan `settings.js`: lulus.

## Urutan SQL yang direkomendasikan

Jalankan file SQL sesuai urutan fitur yang memang dipakai toko. Untuk konfigurasi lengkap pada ZIP ini:

1. `member_system.sql`
2. `member_shop_upgrade.sql`
3. `store_upgrade_all.sql`
4. `mega_features.sql`
5. `owner_center_fix.sql`
6. `staff_login_fix.sql`
7. `store_visuals_upgrade.sql`
8. `stability_patch.sql` **TERAKHIR**

`stability_patch.sql` harus dijalankan terakhir agar hak akses RPC lama yang sudah diperbaiki tidak dikembalikan oleh patch sebelumnya.

## Catatan

Frontend menggunakan Supabase `anon` key. Itu normal untuk aplikasi browser selama RLS dan hak akses database diterapkan seperti pada patch ini. Jangan pernah mengganti key tersebut dengan `service_role` key.

## Struktur paket
Paket final berisi 33 file di dalam 1 folder root `Kenzz-market-main/` (34 entri ZIP jika folder root ikut dihitung).


## Fitur jadwal anime
- Ditambahkan `anime-schedule.html` dengan tautan jadwal dan berita LiveChart.me serta tampilan embed dengan tautan cadangan.
- Data jadwal tetap dikelola oleh LiveChart.me; penyematan dapat tidak tampil jika sumber membatasi iframe.
