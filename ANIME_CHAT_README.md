KENZZ STORE — Perbaikan navigasi Anime Center & Chat

Perubahan
- Menghapus seluruh bagian “Aplikasi Populer Saat Ini” dari index.html.
- Menambahkan tombol Chat Komunitas di area hero beranda.
- Mempertahankan menu Anime Center dan Chat Komunitas.
- Memperjelas pesan error chat jika tabel Supabase belum tersedia.
- Mempertahankan seluruh file dan halaman lama lainnya.

PENTING: agar chat benar-benar bekerja bersama, tabel database harus dibuat satu kali.
1. Buka Supabase Dashboard untuk proyek yang dipakai Kenzz Store.
2. Pilih SQL Editor → New query.
3. Buka file chat_setup.sql dari ZIP ini, salin seluruh isinya, lalu Run.
4. Di Supabase → Database → Publications/Realtime, pastikan public.kenzz_chat_messages masuk ke supabase_realtime jika SQL tidak menambahkannya otomatis.
5. Deploy/unggah SEMUA isi folder Kenzz-market-main ke hosting, dengan index.html di root situs bersama chat.html dan anime-schedule.html.
6. Buka situs, refresh keras / bersihkan cache, lalu uji tombol Anime Center dan Chat Komunitas.

Tentang LiveChart.me
LiveChart.me menolak embed di sebagian browser/host (X-Frame-Options/CSP). Itu pembatasan situs sumber, bukan kesalahan CSS Kenzz Store. Gunakan tombol “Buka tab baru” untuk melihat jadwal resminya. Countdown/favorit lokal tetap tersedia.

Catatan: ZIP tidak dapat mengubah situs yang sudah online secara otomatis. Perubahan baru terlihat setelah seluruh file di-deploy ke hosting yang benar.
