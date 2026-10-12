KENZZ STORE — Anime Center + Community Chat
==========================================

Perubahan utama
- Memperbarui anime-schedule.html menjadi Anime Center dengan tab jadwal LiveChart.me, countdown pribadi, pantauan season/S2, favorit, dan notifikasi browser.
- Menambahkan chat.html untuk chat komunitas menggunakan Supabase Realtime.
- Menambahkan tautan Anime Center dan Chat Komunitas ke menu beranda serta shortcut bawah.
- File lama dipertahankan di ZIP ini.

Cara pakai Anime Center
1. Buka anime-schedule.html dari hosting website.
2. Jadwal resmi dibuka/di-embed dari LiveChart.me. Jika embed ditolak situs sumber, klik Buka tab baru.
3. Countdown memerlukan input tanggal dan waktu yang diverifikasi sendiri; fitur ini tidak mengambil data rilis otomatis dari LiveChart.
4. Favorit, pantauan season, countdown, dan status notifikasi disimpan di localStorage browser/perangkat saat ini.
5. Notifikasi lokal perlu izin browser dan halaman terbuka agar pengecekan berjalan.

Aktifkan Chat Komunitas
1. Buka Supabase Dashboard proyek yang sudah dipakai Kenzz Store.
2. Masuk ke SQL Editor dan jalankan seluruh isi chat_setup.sql.
3. Pastikan Realtime diaktifkan untuk tabel public.kenzz_chat_messages jika publikasi tidak otomatis tersedia.
4. Deploy semua file dari ZIP dengan struktur folder yang sama.

Catatan keamanan chat
Chat ini publik: nickname tidak diverifikasi, pesan bisa dibaca dan dikirim siapa saja yang dapat mengakses halaman. Kebijakan SQL membatasi panjang input tetapi bukan sistem anti-spam penuh. Sebelum digunakan secara luas, disarankan menambah CAPTCHA/rate-limit dan moderasi/admin tools. Jangan menyimpan rahasia di frontend. Supabase anon key adalah kunci publik yang sudah digunakan aplikasi frontend, bukan service-role key.

Kompatibilitas yang diperiksa
- Tautan beranda ke anime-schedule.html dan chat.html.
- Semua halaman lama tetap ada di arsip dasar.
- Input dan keluaran pengguna pada dua halaman baru di-escape saat dirender; URL eksternal hanya menerima http/https.
- Tidak ada klaim API LiveChart.me; jadwal sumber memakai halaman resmi dan countdown pribadi.
