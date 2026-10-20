-- إصلاح أسماء الأطباء العربية التي تلفت أثناء الإنشاء عبر curl
UPDATE doctors SET
  full_name = 'أحمد الكعبي',
  specialty = 'أمراض القلب',
  clinic_name = 'عيادة القلب التخصصية',
  city = 'بغداد',
  working_hours = 'السبت - الخميس 10ص - 6م'
WHERE id = 'd-1792485925193-5803';

UPDATE doctors SET
  full_name = 'سارة الموسوي',
  specialty = 'الأطفال',
  clinic_name = 'عيادة الأطفال الذكية',
  city = 'بغداد',
  working_hours = 'الأحد - الخميس 4م - 9م'
WHERE id = 'd-1792485925555-8216';

UPDATE users SET full_name = 'أحمد الكعبي' WHERE id = 'u-1792485925046-9452';
UPDATE users SET full_name = 'سارة الموسوي' WHERE id = 'u-1792485925430-5167';

SELECT id, full_name, specialty, city, latitude, longitude, region_id, status FROM doctors;
