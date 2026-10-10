# Kenzz Store — Final Deployment Checklist

## 1. Backup
Backup database Supabase sebelum menjalankan migration.

## 2. SQL
Jalankan:

```text
member_system.sql
member_shop_upgrade.sql
store_upgrade_all.sql
mega_features.sql
owner_center_fix.sql
staff_login_fix.sql
store_visuals_upgrade.sql
stability_patch.sql
```

**Penting:** `stability_patch.sql` harus terakhir.

## 3. Setelah SQL
- Logout/login ulang owner dan member.
- Hard refresh browser.
- Test produk biasa.
- Test promo.
- Test cart multi-item.
- Test voucher valid.
- Test voucher kedaluwarsa/batas penggunaan.
- Test stok 0 dan stok kurang dari quantity.
- Test Flash Sale bila digunakan.
- Test register → checkout.
- Test Google/OTP login → pending checkout bila provider tersedia.
- Test owner mengubah status order.
- Pastikan status order hanya berubah melalui RPC server-side; owner tidak mendapat UPDATE langsung pada purchase_history.

## 4. Hasil yang diharapkan
Tidak ada lagi jalur frontend yang langsung memanggil RPC pengurangan stok lama atau INSERT langsung ke `purchase_history`.


## Fitur jadwal anime
- Ditambahkan `anime-schedule.html` dengan tautan jadwal dan berita LiveChart.me serta tampilan embed dengan tautan cadangan.
- Data jadwal tetap dikelola oleh LiveChart.me; penyematan dapat tidak tampil jika sumber membatasi iframe.
