/**
 * أذكار - Adhkar Manager SPA Application Logic
 * إدارة متون الأذكار النبوية وتصنيفاتها وأحاديثها ومصادرها
 */

// ================= INITIAL SEED DATA =================
const DEFAULT_CATEGORIES = [
  { id: 'morning_evening', name: 'أذكار الصباح والمساء', desc: 'الأوراد المأثورة للغدو والآصال', icon: 'wb_sunny', color: '#006a61' },
  { id: 'general', name: 'أذكار عامة ومطلقة', desc: 'التسبيح والتحميد والاستغفار في كل وقت', icon: 'spa', color: '#003527' },
  { id: 'prayer', name: 'أذكار بعد الصلاة', desc: 'ما يقال دبر الصلوات المكتوبة', icon: 'mosque', color: '#006a61' },
  { id: 'sleep', name: 'أذكار النوم والاستيقاظ', desc: 'أدعية وأوراد الإيواء إلى الفراش واليقظة', icon: 'bedtime', color: '#6a3700' },
  { id: 'quranic', name: 'أدعية قرآنية مأثورة', desc: 'الدعاء بما جاء في كتاب الله تعالى', icon: 'menu_book', color: '#064e3b' },
  { id: 'travel', name: 'أدعية السفر والركوب', desc: 'ما يقال عند الخروج والسفر وركوب الدواب', icon: 'flight', color: '#005049' }
];

const DEFAULT_ADHKAR = [
  {
    id: 'dhikr-1',
    adminTitle: 'سيد الاستغفار',
    text: 'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ لَكَ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ.',
    category: 'morning_evening',
    repeats: 1,
    virtue: 'مَن قالها موقناً بها حين يصبح فمات من يومه دخل الجنة، وإذا قالها حين يمسي فمات دخل الجنة.',
    status: 'active',
    createdAt: '2025-01-15T08:00:00Z',
    hadiths: [
      {
        id: 'h-1-1',
        text: 'مَن قالَها مِنَ النَّهارِ مُوقِنًا بها، فَماتَ مِن يَومِهِ قَبْلَ أنْ يُمْسِيَ، فَهو مِن أهْلِ الجَنَّةِ، ومَن قالَها مِنَ اللَّيْلِ وهو مُوقِنٌ بها، فَماتَ قَبْلَ أنْ يُصْبِحَ، فَهو مِن أهْلِ الجَنَّةِ.',
        book: 'صحيح البخاري',
        number: '6306',
        chapter: 'كتاب الدعوات، باب أفضل الاستغفار',
        grade: 'صحيح'
      },
      {
        id: 'h-1-2',
        text: 'سَيِّدُ الاِسْتِغْفَارِ أَنْ يَقُولَ الْعَبْدُ: اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ...',
        book: 'سنن الترمذي',
        number: '3393',
        chapter: 'أبواب الدعوات عن رسول الله صلى الله عليه وسلم',
        grade: 'حسن صحيح'
      }
    ]
  },
  {
    id: 'dhikr-2',
    adminTitle: 'تسبيح مائة مرة لمغفرة الخطايا',
    text: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
    category: 'general',
    repeats: 100,
    virtue: 'حُطَّتْ خطاياه وإن كانت مثل زبد البحر، ولم يأتِ أحد يوم القيامة بأفضل مما جاء به إلا من زاد.',
    status: 'active',
    createdAt: '2025-01-15T08:10:00Z',
    hadiths: [
      {
        id: 'h-2-1',
        text: 'مَن قالَ: سُبْحانَ اللهِ وبِحَمْدِهِ، في يَومٍ مِائَةَ مَرَّةٍ، حُطَّتْ خَطاياهُ، وإنْ كانَتْ مِثْلَ زَبَدِ البَحْرِ.',
        book: 'صحيح البخاري',
        number: '6405',
        chapter: 'كتاب الدعوات، باب فضل التسبيح',
        grade: 'صحيح'
      },
      {
        id: 'h-2-2',
        text: 'مَن قالَ حِينَ يُصْبِحُ وَحِينَ يُمْسِي: سُبْحَانَ اللهِ وَبِحَمْدِهِ، مِئَةَ مَرَّةٍ، لَمْ يَأْتِ أَحَدٌ يَوْمَ القِيَامَةِ، بِأَفْضَلَ ممَّا جَاءَ به، إِلَّا أَحَدٌ قالَ مِثْلَ ما قالَ، أَوْ زَادَ عليه.',
        book: 'صحيح مسلم',
        number: '2692',
        chapter: 'كتاب الذكر والدعاء والتوبة، باب فضل التهليل والتسبيح',
        grade: 'صحيح'
      }
    ]
  },
  {
    id: 'dhikr-3',
    adminTitle: 'الاستغفار والسلام عقب الصلاة',
    text: 'أَسْتَغْفِرُ اللَّهَ، أَسْتَغْفِرُ اللَّهَ، أَسْتَغْفِرُ اللَّهَ، اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ، تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ.',
    category: 'prayer',
    repeats: 1,
    virtue: 'استفتاح الأوراد النبوية بعد السلام من كل فريضة.',
    status: 'active',
    createdAt: '2025-01-15T08:20:00Z',
    hadiths: [
      {
        id: 'h-3-1',
        text: 'كانَ رَسولُ اللهِ صَلَّى اللَّهُ عليه وسلَّمَ، إذَا انْصَرَفَ مِن صَلَاتِهِ اسْتَغْفَرَ ثَلَاثًا، وَقالَ: اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ، تَبَارَكْتَ ذَا الجَلَالِ وَالإِكْرَامِ.',
        book: 'صحيح مسلم',
        number: '591',
        chapter: 'كتاب المساجد ومواضع الصلاة، باب استحباب الذكر بعد الصلاة',
        grade: 'صحيح'
      }
    ]
  },
  {
    id: 'dhikr-4',
    adminTitle: 'دعاء النوم ووضع الجنب',
    text: 'بِاسْمِكَ رَبِّي وَضَعْتُ جَنْبِي وَبِكَ أَرْفَعُهُ، إِنْ أَمْسَكْتَ نَفْسِي فَارْحَمْهَا، وَإِنْ أَرْسَلْتَهَا فَاحْفَظْهَا بِمَا تَحْفَظُ بِهِ عِبَادَكَ الصَّالِحِينَ.',
    category: 'sleep',
    repeats: 1,
    virtue: 'حفظ النفس وبركتها عند المنام وإيكال حفظها إلى الله تعالى.',
    status: 'active',
    createdAt: '2025-01-15T08:30:00Z',
    hadiths: [
      {
        id: 'h-4-1',
        text: 'إِذَا أَوَى أَحَدُكُمْ إِلَى فِرَاشِهِ فَلْيَنْفُضْ فِرَاشَهُ بِدَاخِلَةِ إِزَارِهِ، فَإِنَّهُ لَا يَدْرِي مَا خَلَفَهُ عَلَيْهِ، ثُمَّ يَقُولُ: بِاسْمِكَ رَبِّي وَضَعْتُ جَنْبِي وَبِكَ أَرْفَعُهُ...',
        book: 'صحيح البخاري',
        number: '6320',
        chapter: 'كتاب الدعوات، باب التعوذ والقراءة عند المنام',
        grade: 'صحيح'
      }
    ]
  },
  {
    id: 'dhikr-5',
    adminTitle: 'الرضا بالله رباً وبالإسلام ديناً',
    text: 'رَضِيتُ بِاللَّهِ رَبًّا، وَبِالإِسْلَامِ دِينًا، وَبِمُحَمَّدٍ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ نَبِيًّا.',
    category: 'morning_evening',
    repeats: 3,
    virtue: 'كان حقاً على الله أن يرضيه يوم القيامة.',
    status: 'active',
    createdAt: '2025-01-15T08:40:00Z',
    hadiths: [
      {
        id: 'h-5-1',
        text: 'ما مِن عَبْدٍ مُسْلِمٍ يَقُولُ حِينَ يُصْبِحُ وَحِينَ يُمْسِي ثَلَاثَ مَرَّاتٍ: رَضِيتُ بِاللَّهِ رَبًّا، وَبِالإِسْلَامِ دِينًا، وَبِمُحَمَّدٍ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ نَبِيًّا، إِلَّا كَانَ حَقًّا عَلَى اللَّهِ أَنْ يُرْضِيَهُ يَوْمَ القِيَامَةِ.',
        book: 'سنن الترمذي',
        number: '3389',
        chapter: 'أبواب الدعوات عن رسول الله صلى الله عليه وسلم',
        grade: 'حسن صحيح'
      }
    ]
  },
  {
    id: 'dhikr-6',
    adminTitle: 'كنز من كنوز الجنة (الحوقلة)',
    text: 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
    category: 'general',
    repeats: 1,
    virtue: 'كنز من كنوز الجنة، وباب عظيم للتبرؤ من الحول والقوة إلا بالله.',
    status: 'active',
    createdAt: '2025-01-15T08:50:00Z',
    hadiths: [
      {
        id: 'h-6-1',
        text: 'يا عبدَ اللهِ بنَ قيسٍ، ألَا أدُلُّكَ على كَنزٍ من كُنوزِ الجَنَّةِ؟ فقلتُ: بلى يا رسولَ اللهِ، قال: قُلْ: لا حَولَ ولا قُوَّةَ إلَّا باللهِ.',
        book: 'صحيح البخاري',
        number: '6384',
        chapter: 'كتاب المغازي وكتاب الدعوات',
        grade: 'متفق عليه'
      }
    ]
  },
  {
    id: 'dhikr-7',
    adminTitle: 'دعاء ركوب الدابة والسفر',
    text: 'سُبْحَانَ الَّذِي سَخَّرَ لَنَا هَذَا وَمَا كُنَّا لَهُ مُقْرِنِينَ، وَإِنَّا إِلَى رَبِّنَا لَمُنْقَلِبُونَ، اللَّهُمَّ إِنَّا نَسْأَلُكَ فِي سَفَرِنَا هَذَا الْبِرَّ وَالتَّقْوَى، وَمِنَ الْعَمَلِ مَا تَرْضَى.',
    category: 'travel',
    repeats: 1,
    virtue: 'حفظ المسافر وتيسير طريقه وسلامة الرجوع.',
    status: 'active',
    createdAt: '2025-01-15T09:00:00Z',
    hadiths: [
      {
        id: 'h-7-1',
        text: 'أنَّ رَسولَ اللهِ صَلَّى اللَّهُ عليه وسلَّمَ كانَ إذَا اسْتَوَى علَى بَعِيرِهِ خَارِجًا إلى سَفَرٍ، كَبَّرَ ثَلَاثًا، ثُمَّ قالَ: سُبْحَانَ الذي سَخَّرَ لَنَا هذا...',
        book: 'صحيح مسلم',
        number: '1342',
        chapter: 'كتاب الحج، باب ما يقول إذا ركب إلى سفر الحج وغيره',
        grade: 'صحيح'
      }
    ]
  },
  {
    id: 'dhikr-8',
    adminTitle: 'الاستعاذة من الهم والحزن والعجز',
    text: 'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ، وَالْعَجْزِ وَالْكَسَلِ، وَالْجُبْنِ وَالْبُخْلِ، وَضَلَعِ الدَّيْنِ، وَغَلَبَةِ الرِّجَالِ.',
    category: 'morning_evening',
    repeats: 1,
    virtue: 'دفع الكرب والهم وقضاء الدين وصلاح الأحوال كلها.',
    status: 'active',
    createdAt: '2025-01-15T09:10:00Z',
    hadiths: [
      {
        id: 'h-8-1',
        text: 'كانَ النبيُّ صَلَّى اللهُ عليه وسلَّمَ يقولُ: اللَّهُمَّ إنِّي أعُوذُ بكَ مِنَ الهَمِّ والحَزَنِ، والعَجْزِ والكَسَلِ...',
        book: 'صحيح البخاري',
        number: '2893',
        chapter: 'كتاب الجهاد والسير، باب الدعاء بالجهاد والمغفرة',
        grade: 'صحيح'
      }
    ]
  }
];

// ================= APP STATE =================
const STORAGE_KEY_CATEGORIES = 'adhkar_categories_v1';
const STORAGE_KEY_ADHKAR = 'adhkar_items_v1';

let categories = [];
let adhkar = [];
let currentCategoryFilter = 'all';
let verifiedOnlyFilter = false;
let currentSearchQuery = '';
let activeDhikrCounterState = {};

// ================= STORAGE INITIALIZATION =================
function initStorage() {
  try {
    const savedCategories = localStorage.getItem(STORAGE_KEY_CATEGORIES);
    if (savedCategories) {
      categories = JSON.parse(savedCategories);
    } else {
      categories = [...DEFAULT_CATEGORIES];
      localStorage.setItem(STORAGE_KEY_CATEGORIES, JSON.stringify(categories));
    }

    const savedAdhkar = localStorage.getItem(STORAGE_KEY_ADHKAR);
    if (savedAdhkar) {
      adhkar = JSON.parse(savedAdhkar);
    } else {
      adhkar = [...DEFAULT_ADHKAR];
      localStorage.setItem(STORAGE_KEY_ADHKAR, JSON.stringify(adhkar));
    }
  } catch (e) {
    console.error('Storage error, falling back to memory:', e);
    categories = [...DEFAULT_CATEGORIES];
    adhkar = [...DEFAULT_ADHKAR];
  }
}

function saveCategories() {
  try {
    localStorage.setItem(STORAGE_KEY_CATEGORIES, JSON.stringify(categories));
  } catch (e) {
    console.error('Error saving categories:', e);
  }
}

function saveAdhkar() {
  try {
    localStorage.setItem(STORAGE_KEY_ADHKAR, JSON.stringify(adhkar));
  } catch (e) {
    console.error('Error saving adhkar:', e);
  }
}

// ================= NAVIGATION =================
const SECTIONS = ['overview', 'adhkar', 'misbaha', 'add', 'categories', 'backup'];
const SECTION_TITLES = {
  overview: 'نظرة عامة',
  adhkar: 'متون الأذكار',
  misbaha: 'المسبحة الإلكترونية',
  add: 'إضافة وتوثيق ذكر',
  categories: 'أنواع وتصنيفات الأذكار',
  backup: 'النسخ والبيانات'
};

function navigateTo(viewName, options = {}) {
  if (!SECTIONS.includes(viewName)) viewName = 'overview';

  // Toggle views visibility
  SECTIONS.forEach(s => {
    const viewEl = document.getElementById(`view${s.charAt(0).toUpperCase() + s.slice(1)}`);
    const tabEl = document.getElementById(`navTab-${s}`);

    if (viewEl) {
      if (s === viewName) {
        viewEl.classList.remove('hidden');
      } else {
        viewEl.classList.add('hidden');
      }
    }

    if (tabEl) {
      if (s === viewName) {
        tabEl.className = 'nav-tab flex flex-col items-center justify-center gap-1 min-w-[56px] h-12 transition-all text-primary font-bold';
      } else {
        tabEl.className = 'nav-tab flex flex-col items-center justify-center gap-1 min-w-[56px] h-12 text-on-surface-variant hover:text-primary transition-all';
      }
    }
  });

  // Update Section Title in Header
  const titleEl = document.getElementById('currentSectionTitle');
  if (titleEl) titleEl.innerText = SECTION_TITLES[viewName] || 'أذكار';

  // Update URL hash
  if (window.location.hash !== `#${viewName}`) {
    window.location.hash = `#${viewName}`;
  }

  // Refresh view specific data
  if (viewName === 'overview') {
    renderOverview();
  } else if (viewName === 'adhkar') {
    renderAdhkarList();
  } else if (viewName === 'misbaha') {
    initMisbahaSession(options.categoryId || misbahaCategoryId);
  } else if (viewName === 'categories') {
    renderCategoriesGrid();
  } else if (viewName === 'add') {
    if (!options.isEditing) {
      resetAddForm();
    }
  }

  window.scrollTo({ top: 0, behavior: 'smooth' });
}

// Listen to hash change for browser back/forward buttons
window.addEventListener('hashchange', () => {
  const hash = window.location.hash.replace('#', '');
  if (SECTIONS.includes(hash)) {
    navigateTo(hash);
  }
});

// ================= OVERVIEW / DASHBOARD RENDERER =================
function renderOverview() {
  const total = adhkar.length;
  const withHadith = adhkar.filter(d => Array.isArray(d.hadiths) && d.hadiths.length > 0).length;
  const needsHadith = total - withHadith;
  const percent = total > 0 ? Math.round((withHadith / total) * 100) : 0;

  document.getElementById('statTotalAdhkar').innerText = total;
  document.getElementById('statDocumented').innerText = withHadith;
  document.getElementById('statDocumentedPercent').innerText = `${percent}% موثّق`;
  document.getElementById('statCategoriesCount').innerText = categories.length;
  document.getElementById('statNeedsHadith').innerText = needsHadith;
  document.getElementById('overviewTotalBadge').innerText = `${total} ذكر كليًا`;

  // Update Hijri Date Text
  try {
    const today = new Date();
    const hijriFormatter = new Intl.DateTimeFormat('ar-SA-u-ca-islamic', {
      day: 'numeric',
      month: 'long',
      year: 'numeric'
    });
    const gregorianFormatter = new Intl.DateTimeFormat('ar-EG', {
      day: 'numeric',
      month: 'long',
      year: 'numeric'
    });
    const dateStr = `${hijriFormatter.format(today)} • ${gregorianFormatter.format(today)}`;
    document.getElementById('overviewDateDisplay').innerText = dateStr;
  } catch (e) {
    document.getElementById('overviewDateDisplay').innerText = 'الأوراد اليومية المأثورة';
  }

  // Render Multi-segment bar for Category Distribution
  const multiBar = document.getElementById('overviewCategoryMultiBar');
  const cardsGrid = document.getElementById('overviewCategoryCardsGrid');
  multiBar.innerHTML = '';
  cardsGrid.innerHTML = '';

  const palette = ['#003527', '#006a61', '#6a3700', '#0b513d', '#4a2400', '#2b6954', '#707974'];

  categories.forEach((cat, index) => {
    const count = adhkar.filter(d => d.category === cat.id).length;
    const catPercent = total > 0 ? Math.round((count / total) * 100) : 0;
    const color = cat.color || palette[index % palette.length];

    if (catPercent > 0) {
      const seg = document.createElement('div');
      seg.className = 'h-full transition-all';
      seg.style.width = `${catPercent}%`;
      seg.style.backgroundColor = color;
      seg.title = `${cat.name}: ${count} ذكر (${catPercent}%)`;
      multiBar.appendChild(seg);
    }

    // Category Card in Grid
    const card = document.createElement('div');
    card.className = 'p-3 rounded-xl bg-surface-container-low hover:bg-surface-container transition-all cursor-pointer border border-surface-container-high/40 flex flex-col gap-1.5';
    card.onclick = () => {
      currentCategoryFilter = cat.id;
      navigateTo('adhkar');
    };
    card.innerHTML = `
      <div class="flex items-center justify-between">
        <div class="flex items-center gap-2">
          <span class="w-2.5 h-2.5 rounded-full shrink-0" style="background-color: ${color};"></span>
          <span class="text-xs font-semibold text-on-surface truncate">${cat.name}</span>
        </div>
        <span class="text-xs font-bold" style="color: ${color};">${count} ذكر (${catPercent}%)</span>
      </div>
      <div class="w-full h-1.5 rounded-full bg-surface-variant overflow-hidden">
        <div class="h-full rounded-full transition-all" style="width: ${catPercent}%; background-color: ${color};"></div>
      </div>
      <div class="flex items-center justify-between pt-1 text-[11px]">
        <span class="text-primary hover:underline">عرض القائمة</span>
        <button onclick="event.stopPropagation(); startMisbaha('${cat.id}')" class="text-secondary font-bold hover:underline flex items-center gap-0.5">
          <span class="material-symbols-outlined text-[14px]">touch_app</span>
          <span>بدء بالمسبحة</span>
        </button>
      </div>
    `;
    cardsGrid.appendChild(card);
  });

  // Recent Adhkar List
  const recentList = document.getElementById('overviewRecentList');
  recentList.innerHTML = '';

  const sortedAdhkar = [...adhkar].sort((a, b) => new Date(b.createdAt || 0) - new Date(a.createdAt || 0)).slice(0, 4);

  if (sortedAdhkar.length === 0) {
    recentList.innerHTML = '<div class="py-4 text-center text-xs text-outline">لا توجد أذكار مسجلة بعد.</div>';
    return;
  }

  sortedAdhkar.forEach(d => {
    const cat = categories.find(c => c.id === d.category) || { name: 'عام' };
    const hadithCount = (d.hadiths || []).length;
    const itemEl = document.createElement('div');
    itemEl.className = 'py-3 flex items-start justify-between gap-3 hover:bg-surface-container-low/40 px-2 rounded-lg transition-colors cursor-pointer';
    itemEl.onclick = () => openDetailModal(d.id);

    itemEl.innerHTML = `
      <div class="flex-1 min-w-0">
        <div class="flex items-center gap-2 mb-1">
          <span class="text-[11px] font-semibold text-secondary bg-secondary-container/40 px-2 py-0.5 rounded-md">${cat.name}</span>
          <span class="text-xs font-bold text-on-surface truncate">${d.adminTitle || 'ذكر نبوي'}</span>
          ${hadithCount > 0 
            ? `<span class="text-[10px] bg-tertiary-fixed text-on-tertiary-fixed px-1.5 py-0.2 rounded font-medium flex items-center gap-0.5"><span class="material-symbols-outlined text-[12px]">verified</span> مسند</span>` 
            : `<span class="text-[10px] bg-surface-container text-outline px-1.5 py-0.2 rounded font-medium">غير مسند</span>`}
        </div>
        <p class="text-xs font-dhikr text-on-surface-variant truncate">${d.text}</p>
      </div>
      <div class="flex items-center gap-1 shrink-0 pt-1">
        <button onclick="event.stopPropagation(); editDhikr('${d.id}')" class="w-7 h-7 rounded text-outline hover:text-primary hover:bg-surface-container flex items-center justify-center" title="تعديل">
          <span class="material-symbols-outlined text-[16px]">edit</span>
        </button>
      </div>
    `;
    recentList.appendChild(itemEl);
  });
}

// ================= ADHKAR LIST & CARDS RENDERER =================
function renderCategoryChips() {
  const container = document.getElementById('dynamicCategoryChips');
  container.innerHTML = '';

  // Update All count
  document.getElementById('countChip-all').innerText = adhkar.length;

  categories.forEach(cat => {
    const count = adhkar.filter(d => d.category === cat.id).length;
    const isActive = currentCategoryFilter === cat.id;

    const btn = document.createElement('button');
    btn.className = `cat-chip px-3 py-1.5 rounded-full font-semibold transition-colors shrink-0 ${
      isActive ? 'bg-primary text-on-primary shadow-sm' : 'bg-surface-container text-on-surface hover:bg-surface-container-high'
    }`;
    btn.onclick = () => filterByCategory(cat.id);
    btn.innerHTML = `${cat.name} (${count})`;
    container.appendChild(btn);
  });

  // Highlight 'all' chip if selected
  const allBtn = document.getElementById('catChip-all');
  if (currentCategoryFilter === 'all') {
    allBtn.className = 'cat-chip px-3 py-1.5 rounded-full font-semibold transition-colors shrink-0 bg-primary text-on-primary shadow-sm';
  } else {
    allBtn.className = 'cat-chip px-3 py-1.5 rounded-full font-semibold transition-colors shrink-0 bg-surface-container text-on-surface hover:bg-surface-container-high';
  }
}

function filterByCategory(catId) {
  currentCategoryFilter = catId;
  renderCategoryChips();
  renderAdhkarList();
}

function toggleVerifiedFilter() {
  verifiedOnlyFilter = !verifiedOnlyFilter;
  const btn = document.getElementById('filterVerifiedOnlyBtn');
  const label = document.getElementById('verifiedFilterLabel');

  if (verifiedOnlyFilter) {
    btn.className = 'px-3 py-1.5 rounded-full font-semibold transition-colors shrink-0 bg-secondary text-white shadow-sm flex items-center gap-1';
    label.innerText = 'الموثّقة فقط (مفعّل)';
  } else {
    btn.className = 'px-3 py-1.5 rounded-full font-semibold transition-colors shrink-0 bg-surface-container text-on-surface hover:bg-surface-container-high flex items-center gap-1 border border-surface-container-high';
    label.innerText = 'موثّقة بالحديث فقط';
  }
  renderAdhkarList();
}

function handleSearchInput() {
  const query = document.getElementById('searchInput').value.trim();
  currentSearchQuery = query.toLowerCase();

  const clearBtn = document.getElementById('clearSearchBtn');
  if (currentSearchQuery.length > 0) {
    clearBtn.classList.remove('hidden');
  } else {
    clearBtn.classList.add('hidden');
  }

  renderAdhkarList();
}

function clearSearch() {
  document.getElementById('searchInput').value = '';
  document.getElementById('clearSearchBtn').classList.add('hidden');
  currentSearchQuery = '';
  renderAdhkarList();
}

function renderAdhkarList() {
  renderCategoryChips();

  const container = document.getElementById('adhkarCardsContainer');
  const emptyState = document.getElementById('adhkarEmptyState');
  container.innerHTML = '';

  // Filter adhkar
  const filtered = adhkar.filter(item => {
    // Category filter
    if (currentCategoryFilter !== 'all' && item.category !== currentCategoryFilter) {
      return false;
    }

    // Verified with hadith filter
    const hasHadith = Array.isArray(item.hadiths) && item.hadiths.length > 0;
    if (verifiedOnlyFilter && !hasHadith) {
      return false;
    }

    // Search query filter
    if (currentSearchQuery) {
      const q = currentSearchQuery;
      const titleMatch = (item.adminTitle || '').toLowerCase().includes(q);
      const textMatch = (item.text || '').toLowerCase().includes(q);
      const virtueMatch = (item.virtue || '').toLowerCase().includes(q);

      // Check hadiths
      const hadithMatch = (item.hadiths || []).some(h => 
        (h.text || '').toLowerCase().includes(q) ||
        (h.book || '').toLowerCase().includes(q) ||
        (h.number || '').toString().toLowerCase().includes(q) ||
        (h.chapter || '').toLowerCase().includes(q) ||
        (h.grade || '').toLowerCase().includes(q)
      );

      if (!titleMatch && !textMatch && !virtueMatch && !hadithMatch) {
        return false;
      }
    }

    return true;
  });

  // Update visible counter
  document.getElementById('adhkarVisibleCount').innerText = `عرض ${filtered.length} من أصل ${adhkar.length} ذكراً`;

  if (filtered.length === 0) {
    emptyState.classList.remove('hidden');
    return;
  } else {
    emptyState.classList.add('hidden');
  }

  // Render cards
  filtered.forEach(item => {
    const cardEl = createDhikrCardElement(item);
    container.appendChild(cardEl);
  });
}

function createDhikrCardElement(item) {
  const cat = categories.find(c => c.id === item.category) || { name: 'عام' };
  const hadiths = item.hadiths || [];
  const hasHadith = hadiths.length > 0;
  const currentCount = activeDhikrCounterState[item.id] || 0;

  const card = document.createElement('div');
  card.className = 'dhikr-item bg-surface-container-lowest rounded-2xl p-4 sm:p-5 shadow-sm hover:shadow-md transition-all border border-surface-container-high/40 relative overflow-hidden space-y-3';
  card.id = `dhikrCard-${item.id}`;

  // Top Meta Bar
  let metaHtml = `
    <div class="flex items-start justify-between gap-3">
      <div class="flex flex-wrap items-center gap-2">
        <span class="bg-secondary-container/40 text-on-secondary-container text-xs px-2.5 py-0.5 rounded-full font-semibold">
          ${cat.name}
        </span>
        <button onclick="handleDhikrCounterClick('${item.id}', ${item.repeats})" class="bg-surface-container hover:bg-primary hover:text-white text-on-surface-variant text-xs px-2.5 py-0.5 rounded-full flex items-center gap-1 font-semibold transition-all cursor-pointer" title="انقر للعد">
          <span class="material-symbols-outlined text-[14px]">replay</span>
          <span id="counterBadge-${item.id}">${item.repeats} مرات (المنجز: ${currentCount})</span>
        </button>
        ${item.status === 'active' 
          ? `<span class="bg-primary-fixed text-on-primary-fixed-variant text-[11px] px-2 py-0.5 rounded-full font-medium">نشط</span>`
          : `<span class="bg-surface-container text-outline text-[11px] px-2 py-0.5 rounded-full font-medium">مسودة</span>`
        }
      </div>

      <!-- Card Top Dropdown / Action Buttons -->
      <div class="flex items-center gap-1">
        <button onclick="openDetailModal('${item.id}')" title="عرض التفاصيل الكاملة" class="w-8 h-8 rounded-lg flex items-center justify-center text-outline hover:text-secondary hover:bg-surface-container transition-colors">
          <span class="material-symbols-outlined text-[18px]">visibility</span>
        </button>
        <button onclick="editDhikr('${item.id}')" title="تعديل الذكر" class="w-8 h-8 rounded-lg flex items-center justify-center text-outline hover:text-primary hover:bg-surface-container transition-colors">
          <span class="material-symbols-outlined text-[18px]">edit</span>
        </button>
        <button onclick="confirmDeleteDhikr('${item.id}')" title="حذف الذكر" class="w-8 h-8 rounded-lg flex items-center justify-center text-outline hover:text-error hover:bg-error-container/30 transition-colors">
          <span class="material-symbols-outlined text-[18px]">delete</span>
        </button>
      </div>
    </div>
  `;

  // Admin Title if present
  let titleHtml = '';
  if (item.adminTitle) {
    titleHtml = `
      <div class="text-xs font-bold text-primary flex items-center gap-1.5">
        <span class="w-1.5 h-1.5 rounded-full bg-primary"></span>
        <span>${item.adminTitle}</span>
      </div>
    `;
  }

  // Devotional Dhikr Arabic Text Box
  let dhikrBoxHtml = `
    <div class="p-3.5 sm:p-4 bg-surface-container-low/60 rounded-xl border border-surface-container-high/30">
      <p class="font-dhikr text-base sm:text-lg text-on-surface font-medium leading-loose select-text text-right" dir="rtl">
        ${item.text}
      </p>
    </div>
  `;

  // Virtue snippet if present
  let virtueHtml = '';
  if (item.virtue) {
    virtueHtml = `
      <div class="text-xs text-on-surface-variant bg-surface-container-lowest p-2.5 rounded-xl border border-surface-container-high/40 flex items-start gap-2">
        <span class="material-symbols-outlined text-[16px] text-primary shrink-0 mt-0.5">auto_awesome</span>
        <div>
          <span class="font-semibold text-primary">فضل الذكر:</span>
          <span>${item.virtue}</span>
        </div>
      </div>
    `;
  }

  // Hadiths Documentation Block
  let hadithSectionHtml = '';
  if (hasHadith) {
    const hadithCardsHtml = hadiths.map((h, i) => {
      const bookText = (h.book || 'مصدر معتمد').trim();
      const bookList = bookText ? bookText.split(/[,،]+/).map(s => s.trim()).filter(Boolean) : [];
      const booksBadgesHtml = bookList.length > 1
        ? bookList.map(b => `<span class="bg-secondary/10 text-secondary border border-secondary/20 px-2 py-0.5 rounded text-[11px] font-semibold">${b}</span>`).join(' ')
        : `<span class="font-semibold">${bookText}</span>`;

      return `
        <div class="bg-surface-container-lowest p-3 rounded-xl border border-surface-container-high/60 flex flex-col gap-1.5">
          <div class="flex items-center justify-between gap-2 flex-wrap text-xs">
            <div class="flex items-center gap-1.5 text-on-surface flex-wrap">
              <span class="material-symbols-outlined text-[18px] text-secondary">menu_book</span>
              ${booksBadgesHtml}
              ${h.number ? `<span class="bg-surface-container px-2 py-0.5 rounded text-[11px] font-mono font-medium text-secondary">#${h.number}</span>` : ''}
            </div>
            ${h.grade && h.grade.trim() ? `
              <span class="bg-tertiary-fixed text-on-tertiary-fixed px-2 py-0.5 rounded-full text-[11px] font-bold flex items-center gap-1">
                <span class="material-symbols-outlined text-[13px]">verified</span>
                <span>${h.grade}</span>
              </span>
            ` : ''}
          </div>
          ${h.chapter ? `<div class="text-[11px] text-outline font-medium">الموضع: ${h.chapter}</div>` : ''}
          ${h.text ? `<p class="text-xs text-on-surface-variant font-body line-clamp-2 mt-0.5 italic">"${h.text}"</p>` : ''}
        </div>
      `;
    }).join('');

    hadithSectionHtml = `
      <div class="bg-surface-container-low p-3 rounded-xl space-y-2">
        <div class="flex items-center justify-between text-xs">
          <span class="font-bold text-secondary flex items-center gap-1.5">
            <span class="material-symbols-outlined text-[18px]">history_edu</span>
            <span>التوثيق بالأحاديث النبوية (${hadiths.length})</span>
          </span>
          <button onclick="copyDhikrWithSanad('${item.id}')" class="text-[11px] text-primary hover:underline flex items-center gap-1">
            <span class="material-symbols-outlined text-[13px]">content_copy</span>
            <span>نسخ الذكر مع التخريج</span>
          </button>
        </div>
        <div class="space-y-2">
          ${hadithCardsHtml}
        </div>
      </div>
    `;
  } else {
    // Missing Hadith Notice Box
    hadithSectionHtml = `
      <div class="bg-tertiary-fixed/30 text-on-tertiary-container p-3 rounded-xl flex items-center justify-between gap-2 text-xs">
        <div class="flex items-center gap-2">
          <span class="material-symbols-outlined text-[18px] text-on-tertiary-container shrink-0">warning_amber</span>
          <span>هذا الذكر غير موثق بحديث مسند حتى الآن</span>
        </div>
        <button onclick="editDhikr('${item.id}')" class="px-3 py-1 bg-surface-container-lowest text-on-tertiary-container hover:bg-tertiary-fixed rounded-lg font-semibold shadow-xs transition-colors shrink-0">
          ربط بحديث الآن
        </button>
      </div>
    `;
  }

  // Footer Actions Row
  let footerHtml = `
    <div class="flex items-center justify-between pt-1 border-t border-surface-container-high/40 text-xs">
      <div class="flex items-center gap-2">
        <button onclick="copyText('${escapeQuote(item.text)}')" class="px-3 py-1.5 rounded-lg bg-surface-container hover:bg-surface-container-high text-on-surface flex items-center gap-1 text-[11px] font-medium transition-colors">
          <span class="material-symbols-outlined text-[14px]">content_copy</span>
          <span>نسخ المتن</span>
        </button>
        <button onclick="handleDhikrCounterClick('${item.id}', ${item.repeats})" class="px-3 py-1.5 rounded-lg bg-primary-fixed text-primary hover:bg-primary-fixed-dim flex items-center gap-1 text-[11px] font-semibold transition-colors">
          <span class="material-symbols-outlined text-[14px]">touch_app</span>
          <span>تسبيح (${currentCount}/${item.repeats})</span>
        </button>
      </div>
      <button onclick="openDetailModal('${item.id}')" class="text-xs text-primary font-semibold hover:underline flex items-center gap-1">
        <span>عرض البطاقة</span>
        <span class="material-symbols-outlined text-[14px]">chevron_left</span>
      </button>
    </div>
  `;

  card.innerHTML = metaHtml + titleHtml + dhikrBoxHtml + virtueHtml + hadithSectionHtml + footerHtml;
  return card;
}

// Interactive Repetition Counter
function handleDhikrCounterClick(dhikrId, targetRepeats) {
  let count = activeDhikrCounterState[dhikrId] || 0;
  count++;

  if (count >= targetRepeats) {
    showToast(`مبارك! أتممت قراءة الذكر (${targetRepeats} مرات)`, 'spa');
    activeDhikrCounterState[dhikrId] = 0; // reset
  } else {
    activeDhikrCounterState[dhikrId] = count;
    showToast(`تم التسبيح: ${count} من ${targetRepeats}`, 'touch_app');
  }

  // Update card badge
  const badge = document.getElementById(`counterBadge-${dhikrId}`);
  if (badge) {
    badge.innerText = `${targetRepeats} مرات (المنجز: ${activeDhikrCounterState[dhikrId] || 0})`;
  }
  renderAdhkarList();
}

// ================= FORM: ADD / EDIT DHIKR =================
let formHadiths = [];

function resetAddForm() {
  document.getElementById('editDhikrId').value = '';
  document.getElementById('formAdminTitle').value = '';
  document.getElementById('formDhikrText').value = '';
  document.getElementById('formRepeatCount').value = '1';
  document.getElementById('formVirtueNotes').value = '';
  document.getElementById('formStatusToggle').checked = true;
  document.getElementById('formHeaderTitle').innerText = 'بطاقة صياغة وتوثيق الذكر';
  document.getElementById('formBreadcrumbAction').innerText = 'إضافة ذكر جديد';
  document.getElementById('formDraftBadge').innerHTML = `
    <span class="material-symbols-outlined text-[15px]">auto_awesome</span>
    <span>مسوّدة جديدة</span>
  `;
  document.getElementById('formSubmitBtnText').innerText = 'حفظ الذكر وتوثيقه المبارك';

  populateCategorySelect();
  updateCharCount();
  handleStatusToggleChange();

  // Reset hadiths with one empty template
  formHadiths = [];
  addEmptyHadithCard();
}

function populateCategorySelect(selectedId = '') {
  const select = document.getElementById('formCategorySelect');
  select.innerHTML = '';

  categories.forEach(cat => {
    const opt = document.createElement('option');
    opt.value = cat.id;
    opt.innerText = cat.name;
    if (cat.id === selectedId) opt.selected = true;
    select.appendChild(opt);
  });
}

function updateCharCount() {
  const text = document.getElementById('formDhikrText').value || '';
  const display = document.getElementById('charCountDisplay');
  display.innerText = `${text.length} حرف`;
}

function adjustRepeat(delta) {
  const input = document.getElementById('formRepeatCount');
  let val = parseInt(input.value) || 1;
  val = Math.max(1, Math.min(1000, val + delta));
  input.value = val;
}

function setRepeat(count) {
  document.getElementById('formRepeatCount').value = count;
}

function handleStatusToggleChange() {
  const isChecked = document.getElementById('formStatusToggle').checked;
  const iconWrap = document.getElementById('formStatusIconWrap');
  const title = document.getElementById('formStatusTitle');
  const desc = document.getElementById('formStatusDesc');

  if (isChecked) {
    iconWrap.className = 'w-8 h-8 rounded-lg bg-primary-fixed flex items-center justify-center text-primary';
    title.innerText = 'حالة الذكر: معتمد ونشط';
    desc.innerText = 'الذكر معتمد للنشر ومتاح فور الحفظ';
  } else {
    iconWrap.className = 'w-8 h-8 rounded-lg bg-surface-container-high flex items-center justify-center text-outline';
    title.innerText = 'حالة الذكر: مسوّدة قيد المراجعة';
    desc.innerText = 'لن يظهر للمستخدمين حتى يتم اعتماده';
  }
}

// Hadith Cards in Form
function addEmptyHadithCard() {
  const newHadith = {
    id: `temp-h-${Date.now()}-${Math.random().toString(36).substr(2, 4)}`,
    text: '',
    book: '',
    number: '',
    chapter: '',
    grade: ''
  };
  formHadiths.push(newHadith);
  renderFormHadithsList();
}

function removeHadithCard(tempId) {
  formHadiths = formHadiths.filter(h => h.id !== tempId);
  renderFormHadithsList();
  showToast('تمت إزالة بطاقة الحديث');
}

function syncHadithFormData() {
  formHadiths.forEach(h => {
    const textEl = document.getElementById(`hadithText-${h.id}`);
    const bookEl = document.getElementById(`hadithBook-${h.id}`);
    const numEl = document.getElementById(`hadithNum-${h.id}`);
    const gradeEl = document.getElementById(`hadithGrade-${h.id}`);
    const chapEl = document.getElementById(`hadithChap-${h.id}`);

    if (textEl) h.text = textEl.value.trim();
    if (bookEl) h.book = bookEl.value.trim();
    if (numEl) h.number = numEl.value.trim();
    if (gradeEl) h.grade = gradeEl.value.trim();
    if (chapEl) h.chapter = chapEl.value.trim();
  });
}

function toggleBookChip(hadithId, bookName) {
  const input = document.getElementById(`hadithBook-${hadithId}`);
  if (!input) return;

  let current = input.value.trim();
  let list = current ? current.split(/[,،]+/).map(s => s.trim()).filter(Boolean) : [];

  const index = list.indexOf(bookName);
  if (index >= 0) {
    list.splice(index, 1);
  } else {
    list.push(bookName);
  }

  input.value = list.join('، ');

  const item = formHadiths.find(h => h.id === hadithId);
  if (item) {
    item.book = input.value;
  }

  updateBookChipsVisual(hadithId, list);
}

function updateBookChipsVisual(hadithId, currentList) {
  const container = document.getElementById(`bookChipsContainer-${hadithId}`);
  if (!container) return;

  const buttons = container.querySelectorAll('button[data-book]');
  buttons.forEach(btn => {
    const book = btn.getAttribute('data-book');
    const isSelected = currentList.includes(book);
    if (isSelected) {
      btn.className = 'px-2.5 py-1 rounded-lg text-[11px] font-bold transition-all bg-secondary text-white shadow-xs flex items-center gap-1 cursor-pointer';
      btn.innerHTML = `<span class="material-symbols-outlined text-[13px]">check</span><span>${book}</span>`;
    } else {
      btn.className = 'px-2.5 py-1 rounded-lg text-[11px] font-medium transition-all bg-surface-container hover:bg-surface-container-high text-on-surface border border-surface-container-high/60 flex items-center gap-1 cursor-pointer';
      btn.innerHTML = `<span>+</span><span>${book}</span>`;
    }
  });
}

function handleBookInputManual(hadithId) {
  const input = document.getElementById(`hadithBook-${hadithId}`);
  if (!input) return;
  const current = input.value.trim();
  const list = current ? current.split(/[,،]+/).map(s => s.trim()).filter(Boolean) : [];
  updateBookChipsVisual(hadithId, list);

  const item = formHadiths.find(h => h.id === hadithId);
  if (item) {
    item.book = input.value;
  }
}

function renderFormHadithsList() {
  const container = document.getElementById('formHadithsContainer');
  document.getElementById('formHadithCountNumber').innerText = formHadiths.length;
  container.innerHTML = '';

  const quickBooks = [
    'صحيح البخاري',
    'صحيح مسلم',
    'سنن أبي داود',
    'سنن الترمذي',
    'سنن النسائي',
    'سنن ابن ماجه',
    'مسند أحمد',
    'موطأ مالك'
  ];

  const grades = [
    { value: '', label: '-- بدون تحديد (فارغة) --' },
    { value: 'صحيح', label: 'صحيح' },
    { value: 'حسن', label: 'حسن' },
    { value: 'متفق عليه', label: 'متفق عليه' },
    { value: 'حسن صحيح', label: 'حسن صحيح' },
    { value: 'صحيح لغيره', label: 'صحيح لغيره' },
    { value: 'حسن لغيره', label: 'حسن لغيره' },
    { value: 'ضعيف', label: 'ضعيف' },
    { value: 'أخرى', label: 'أخرى' }
  ];

  formHadiths.forEach((h, index) => {
    const card = document.createElement('div');
    card.className = 'hadith-card bg-surface-container-low rounded-2xl p-4 border border-surface-container-high/60 space-y-3.5';
    card.id = `formHadithCard-${h.id}`;

    const currentBookText = (h.book || '').trim();
    const currentBookList = currentBookText ? currentBookText.split(/[,،]+/).map(s => s.trim()).filter(Boolean) : [];

    card.innerHTML = `
      <div class="flex items-center justify-between border-b border-surface-container-high/50 pb-2">
        <div class="flex items-center gap-2">
          <span class="w-6 h-6 rounded-full bg-secondary text-white text-xs font-bold flex items-center justify-center">${index + 1}</span>
          <span class="text-xs font-bold text-secondary">بطاقة السند والتوثيق (${index + 1})</span>
        </div>
        <button type="button" onclick="removeHadithCard('${h.id}')" class="text-xs text-error hover:bg-error-container/40 px-2.5 py-1 rounded-lg flex items-center gap-1 transition-colors">
          <span class="material-symbols-outlined text-[16px]">delete</span>
          <span>إزالة الحديث</span>
        </button>
      </div>

      <!-- متن الحديث النبوي -->
      <div class="space-y-1">
        <label class="text-xs font-semibold text-on-surface">متن الحديث النبوي الشريف</label>
        <textarea id="hadithText-${h.id}" rows="2" placeholder="أدخل متن الحديث النبوي المأثور بالسند أو المعنى..." class="w-full bg-surface-container-lowest text-on-surface p-2.5 rounded-xl text-xs sm:text-sm focus:outline-none focus:ring-2 focus:ring-secondary transition-all">${h.text || ''}</textarea>
      </div>

      <!-- مصدر الحديث (كتاب أو كتابان أو أكثر) -->
      <div class="space-y-1.5 p-3 rounded-xl bg-surface-container-lowest border border-surface-container-high/50">
        <div class="flex items-center justify-between">
          <label class="text-xs font-semibold text-on-surface flex items-center gap-1">
            <span class="material-symbols-outlined text-[16px] text-secondary">menu_book</span>
            <span>المصدر / الكتاب (يمكن تحديد كتاب واحد، كتابان، أو أكثر)</span>
          </label>
          <span class="text-[11px] text-outline">اختر بالنقر أو اكتب مباشرة</span>
        </div>

        <div class="relative">
          <input id="hadithBook-${h.id}" type="text" value="${escapeHtml(h.book || '')}" oninput="handleBookInputManual('${h.id}')" placeholder="مثال: صحيح البخاري، صحيح مسلم أو اكتب مصدراً آخر..." class="w-full bg-surface-container-low text-on-surface px-3 py-2 rounded-xl text-xs sm:text-sm focus:outline-none focus:ring-2 focus:ring-secondary transition-all"/>
        </div>

        <div class="pt-1">
          <div class="text-[11px] text-on-surface-variant font-medium mb-1">الكتب المعتمدة (انقر لتحديد أو إزالة الكتاب):</div>
          <div id="bookChipsContainer-${h.id}" class="flex flex-wrap gap-1.5">
            ${quickBooks.map(b => {
              const isSelected = currentBookList.includes(b);
              return `
                <button type="button" data-book="${b}" onclick="toggleBookChip('${h.id}', '${b}')" class="px-2.5 py-1 rounded-lg text-[11px] transition-all flex items-center gap-1 cursor-pointer ${
                  isSelected 
                    ? 'bg-secondary text-white font-bold shadow-xs' 
                    : 'bg-surface-container hover:bg-surface-container-high text-on-surface border border-surface-container-high/60 font-medium'
                }">
                  ${isSelected ? '<span class="material-symbols-outlined text-[13px]">check</span>' : '<span>+</span>'}
                  <span>${b}</span>
                </button>
              `;
            }).join('')}
          </div>
        </div>
      </div>

      <!-- رقم الحديث ودرجة الصحة (اختيارية ويمكن إفراغها) -->
      <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
        <div class="space-y-1">
          <label class="text-[11px] font-semibold text-on-surface">رقم الحديث (في الطبعات المعتمدة)</label>
          <input id="hadithNum-${h.id}" type="text" value="${h.number || ''}" placeholder="مثال: 6306، 2692" class="w-full bg-surface-container-lowest text-on-surface p-2.5 rounded-xl text-xs font-mono focus:outline-none focus:ring-2 focus:ring-secondary"/>
        </div>

        <div class="space-y-1">
          <div class="flex items-center justify-between">
            <label class="text-[11px] font-semibold text-on-surface">درجة الصحة</label>
            <span class="text-[10px] text-outline">(اختيارية - يمكن إفراغها)</span>
          </div>
          <select id="hadithGrade-${h.id}" class="w-full bg-surface-container-lowest text-on-surface p-2.5 rounded-xl text-xs focus:outline-none focus:ring-2 focus:ring-secondary cursor-pointer">
            ${grades.map(g => `<option value="${g.value}" ${g.value === (h.grade || '') ? 'selected' : ''}>${g.label}</option>`).join('')}
          </select>
        </div>
      </div>

      <!-- الباب أو الموضع في الكتاب -->
      <div class="space-y-1">
        <label class="text-[11px] font-semibold text-on-surface">الباب أو الموضع في الكتاب (أين ورد الحديث؟)</label>
        <input id="hadithChap-${h.id}" type="text" value="${h.chapter || ''}" placeholder="مثال: كتاب الدعوات، باب أفضل الاستغفار" class="w-full bg-surface-container-lowest text-on-surface p-2.5 rounded-xl text-xs focus:outline-none focus:ring-2 focus:ring-secondary"/>
      </div>
    `;

    container.appendChild(card);
  });
}

function handleFormSubmit(event) {
  event.preventDefault();
  syncHadithFormData();

  const editId = document.getElementById('editDhikrId').value;
  const adminTitle = document.getElementById('formAdminTitle').value.trim();
  const dhikrText = document.getElementById('formDhikrText').value.trim();
  const category = document.getElementById('formCategorySelect').value;
  const repeats = parseInt(document.getElementById('formRepeatCount').value) || 1;
  const virtue = document.getElementById('formVirtueNotes').value.trim();
  const status = document.getElementById('formStatusToggle').checked ? 'active' : 'draft';

  if (!dhikrText) {
    showToast('يرجى كتابة نص الذكر أولاً', 'error');
    document.getElementById('formDhikrText').focus();
    return;
  }

  // Filter hadiths with at least some content
  const cleanHadiths = formHadiths.filter(h => h.text || h.number || h.chapter || h.book || h.grade).map((h, i) => ({
    id: h.id.startsWith('temp') ? `h-${Date.now()}-${i}` : h.id,
    text: h.text || '',
    book: h.book || '',
    number: h.number || '',
    chapter: h.chapter || '',
    grade: h.grade || ''
  }));

  if (editId) {
    // Updating existing dhikr
    const index = adhkar.findIndex(d => d.id === editId);
    if (index !== -1) {
      adhkar[index] = {
        ...adhkar[index],
        adminTitle,
        text: dhikrText,
        category,
        repeats,
        virtue,
        status,
        hadiths: cleanHadiths,
        updatedAt: new Date().toISOString()
      };
      saveAdhkar();
      showToast('تم تحديث الذكر وتوثيقه بنجاح المبارك!');
    }
  } else {
    // Creating new dhikr
    const newDhikr = {
      id: `dhikr-${Date.now()}`,
      adminTitle,
      text: dhikrText,
      category,
      repeats,
      virtue,
      status,
      hadiths: cleanHadiths,
      createdAt: new Date().toISOString()
    };
    adhkar.unshift(newDhikr);
    saveAdhkar();
    showToast('تمت إضافة الذكر وتوثيقه بنجاح تام!');
  }

  // Navigate to list
  navigateTo('adhkar');
}

function submitAndAddNew() {
  syncHadithFormData();

  const adminTitle = document.getElementById('formAdminTitle').value.trim();
  const dhikrText = document.getElementById('formDhikrText').value.trim();
  const category = document.getElementById('formCategorySelect').value;
  const repeats = parseInt(document.getElementById('formRepeatCount').value) || 1;
  const virtue = document.getElementById('formVirtueNotes').value.trim();
  const status = document.getElementById('formStatusToggle').checked ? 'active' : 'draft';

  if (!dhikrText) {
    showToast('يرجى كتابة نص الذكر أولاً', 'error');
    document.getElementById('formDhikrText').focus();
    return;
  }

  const cleanHadiths = formHadiths.filter(h => h.text || h.number || h.chapter || h.book || h.grade).map((h, i) => ({
    id: `h-${Date.now()}-${i}`,
    text: h.text || '',
    book: h.book || '',
    number: h.number || '',
    chapter: h.chapter || '',
    grade: h.grade || ''
  }));

  const newDhikr = {
    id: `dhikr-${Date.now()}`,
    adminTitle,
    text: dhikrText,
    category,
    repeats,
    virtue,
    status,
    hadiths: cleanHadiths,
    createdAt: new Date().toISOString()
  };
  adhkar.unshift(newDhikr);
  saveAdhkar();

  showToast('تم الحفظ بنجاح، وتجهيز نموذج لذكر جديد');
  resetAddForm();
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function editDhikr(id) {
  const item = adhkar.find(d => d.id === id);
  if (!item) return;

  navigateTo('add', { isEditing: true });

  document.getElementById('editDhikrId').value = item.id;
  document.getElementById('formAdminTitle').value = item.adminTitle || '';
  document.getElementById('formDhikrText').value = item.text || '';
  document.getElementById('formRepeatCount').value = item.repeats || 1;
  document.getElementById('formVirtueNotes').value = item.virtue || '';
  document.getElementById('formStatusToggle').checked = item.status === 'active';
  document.getElementById('formHeaderTitle').innerText = `تعديل الذكر: ${item.adminTitle || 'بدون عنوان'}`;
  document.getElementById('formBreadcrumbAction').innerText = 'تعديل الذكر';
  document.getElementById('formDraftBadge').innerHTML = `
    <span class="material-symbols-outlined text-[15px]">edit</span>
    <span>تعديل السجل</span>
  `;
  document.getElementById('formSubmitBtnText').innerText = 'تحديث الذكر والتوثيق';

  populateCategorySelect(item.category);
  updateCharCount();
  handleStatusToggleChange();

  // Load hadiths
  formHadiths = (item.hadiths || []).map(h => ({ ...h }));
  if (formHadiths.length === 0) {
    addEmptyHadithCard();
  } else {
    renderFormHadithsList();
  }
}

function cancelForm() {
  if (confirm('هل أنت متأكد من إلغاء التعديلات؟ سيتم فقد أي تغييرات غير محفوظة.')) {
    navigateTo('adhkar');
  }
}

function confirmDeleteDhikr(id) {
  const item = adhkar.find(d => d.id === id);
  const title = item ? (item.adminTitle || item.text.substring(0, 30)) : '';

  if (confirm(`هل أنت متأكد من حذف هذا الذكر:\n"${title}"؟`)) {
    adhkar = adhkar.filter(d => d.id !== id);
    saveAdhkar();
    showToast('تم حذف الذكر بنجاح');
    renderAdhkarList();
    renderOverview();
  }
}

// ================= CATEGORIES MANAGEMENT =================
function renderCategoriesGrid() {
  const container = document.getElementById('categoriesGridContainer');
  container.innerHTML = '';

  categories.forEach(cat => {
    const count = adhkar.filter(d => d.category === cat.id).length;
    const card = document.createElement('div');
    card.className = 'bg-surface-container-lowest p-5 rounded-2xl shadow-sm border border-surface-container-high/40 flex flex-col justify-between gap-3 hover:shadow-md transition-all';

    card.innerHTML = `
      <div class="space-y-2">
        <div class="flex items-center justify-between">
          <div class="w-10 h-10 rounded-xl flex items-center justify-center text-white" style="background-color: ${cat.color || '#006a61'};">
            <span class="material-symbols-outlined text-[22px]">${cat.icon || 'bookmark'}</span>
          </div>
          <span class="px-2.5 py-1 rounded-full text-xs font-bold bg-surface-container text-on-surface">
            ${count} ذكر
          </span>
        </div>
        <h3 class="font-headline font-bold text-base text-on-surface">${cat.name}</h3>
        <p class="text-xs text-on-surface-variant">${cat.desc || 'تصنيف معتمد للأوراد النبوية'}</p>
      </div>

      <div class="flex items-center justify-between pt-2 border-t border-surface-container-high/40 text-xs">
        <button onclick="currentCategoryFilter = '${cat.id}'; navigateTo('adhkar');" class="text-primary font-semibold hover:underline flex items-center gap-1">
          <span>استعراض الأذكار</span>
          <span class="material-symbols-outlined text-[14px]">chevron_left</span>
        </button>
        <div class="flex items-center gap-2">
          <button onclick="startMisbaha('${cat.id}')" class="px-2.5 py-1 rounded-lg bg-primary-fixed text-primary hover:bg-primary-fixed-dim font-bold flex items-center gap-1 shadow-xs transition-colors">
            <span class="material-symbols-outlined text-[14px]">touch_app</span>
            <span>بدء بالمسبحة</span>
          </button>
          ${count === 0 ? `
            <button onclick="deleteCategory('${cat.id}')" class="text-error hover:underline text-[11px]">حذف</button>
          ` : `
            <span class="text-[11px] text-outline">مفهرس</span>
          `}
        </div>
      </div>
    `;

    container.appendChild(card);
  });
}

function openCategoryModal() {
  document.getElementById('catModalName').value = '';
  document.getElementById('catModalDesc').value = '';
  document.getElementById('catModalIcon').value = 'menu_book';
  document.getElementById('categoryModal').classList.remove('hidden');
}

function closeCategoryModal() {
  document.getElementById('categoryModal').classList.add('hidden');
}

function handleCategoryModalSubmit(event) {
  event.preventDefault();
  const name = document.getElementById('catModalName').value.trim();
  const desc = document.getElementById('catModalDesc').value.trim();
  const icon = document.getElementById('catModalIcon').value;

  if (!name) return;

  const newId = `cat_${Date.now()}`;
  categories.push({
    id: newId,
    name,
    desc,
    icon,
    color: '#006a61'
  });

  saveCategories();
  closeCategoryModal();
  showToast(`تمت إضافة نوع الأذكار "${name}" بنجاح`);

  populateCategorySelect(newId);
  renderCategoriesGrid();
  renderCategoryChips();
}

function deleteCategory(catId) {
  const cat = categories.find(c => c.id === catId);
  if (!cat) return;

  if (confirm(`هل أنت متأكد من حذف نوع "${cat.name}"؟`)) {
    categories = categories.filter(c => c.id !== catId);
    saveCategories();
    showToast('تم حذف التصنيف بنجاح');
    renderCategoriesGrid();
    renderCategoryChips();
  }
}

// ================= DETAIL / READ MODAL =================
function openDetailModal(id) {
  const item = adhkar.find(d => d.id === id);
  if (!item) return;

  const cat = categories.find(c => c.id === item.category) || { name: 'عام' };
  const hadiths = item.hadiths || [];

  document.getElementById('detailModalTitle').innerText = item.adminTitle || 'تفاصيل الذكر الشريف';
  const body = document.getElementById('detailModalBody');

  let hadithsHtml = '';
  if (hadiths.length > 0) {
    hadithsHtml = hadiths.map((h, i) => {
      const bookText = (h.book || 'مصدر معتمد').trim();
      const bookList = bookText ? bookText.split(/[,،]+/).map(s => s.trim()).filter(Boolean) : [];
      const booksBadgesHtml = bookList.length > 1
        ? bookList.map(b => `<span class="bg-secondary/15 text-secondary border border-secondary/30 px-2.5 py-0.5 rounded-md text-xs font-semibold">${b}</span>`).join(' ')
        : `<span>${bookText}</span>`;

      return `
        <div class="bg-surface-container-low p-4 rounded-xl border border-surface-container-high/60 space-y-2">
          <div class="flex items-center justify-between flex-wrap gap-2 text-xs">
            <div class="flex items-center gap-1.5 font-bold text-secondary flex-wrap">
              <span class="material-symbols-outlined text-[18px]">menu_book</span>
              ${booksBadgesHtml}
              ${h.number ? `<span class="bg-surface-container px-2 py-0.5 rounded font-mono text-[11px]">#${h.number}</span>` : ''}
            </div>
            ${h.grade && h.grade.trim() ? `
              <span class="px-2.5 py-0.5 rounded-full text-xs font-bold bg-tertiary-fixed text-on-tertiary-fixed flex items-center gap-1">
                <span class="material-symbols-outlined text-[13px]">verified</span>
                <span>${h.grade}</span>
              </span>
            ` : ''}
          </div>
          ${h.chapter ? `<div class="text-xs text-outline font-medium">أين ورد: ${h.chapter}</div>` : ''}
          ${h.text ? `<p class="text-xs sm:text-sm text-on-surface font-body leading-relaxed bg-surface-container-lowest p-3 rounded-lg border border-surface-container-high/40">"${h.text}"</p>` : ''}
        </div>
      `;
    }).join('');
  } else {
    hadithsHtml = `<div class="p-3 bg-surface-container-low rounded-xl text-xs text-outline text-center">لا يوجد حديث مسند مرتبط بهذا الذكر بعد.</div>`;
  }

  body.innerHTML = `
    <!-- Category & Repetition -->
    <div class="flex items-center justify-between gap-2 flex-wrap">
      <span class="bg-secondary-container/40 text-on-secondary-container text-xs px-3 py-1 rounded-full font-bold">
        ${cat.name}
      </span>
      <span class="bg-primary-fixed text-primary text-xs px-3 py-1 rounded-full font-bold flex items-center gap-1">
        <span class="material-symbols-outlined text-[14px]">replay</span>
        <span>التكرار: ${item.repeats} مرات</span>
      </span>
    </div>

    <!-- Sacred Dhikr Calligraphy Text -->
    <div class="p-4 bg-surface-container-low rounded-xl border border-surface-container-high/50">
      <p class="font-dhikr text-lg sm:text-xl text-primary font-semibold leading-loose select-text text-right" dir="rtl">
        ${item.text}
      </p>
    </div>

    <!-- Virtue -->
    ${item.virtue ? `
      <div class="bg-surface-container-lowest p-3 rounded-xl border border-surface-container-high text-xs space-y-1">
        <span class="font-bold text-primary flex items-center gap-1">
          <span class="material-symbols-outlined text-[16px]">auto_awesome</span>
          <span>فضل الذكر وأثره:</span>
        </span>
        <p class="text-on-surface-variant leading-relaxed">${item.virtue}</p>
      </div>
    ` : ''}

    <!-- Hadiths & Sources -->
    <div class="space-y-2 pt-2">
      <h4 class="text-xs font-bold text-secondary flex items-center gap-1.5">
        <span class="material-symbols-outlined text-[18px]">verified</span>
        <span>الأحاديث النبوية المسندة ومصادر التخريج:</span>
      </h4>
      ${hadithsHtml}
    </div>
  `;

  // Setup edit button in modal
  document.getElementById('detailModalEditBtn').onclick = () => {
    closeDetailModal();
    editDhikr(item.id);
  };

  document.getElementById('detailModal').classList.remove('hidden');
}

function closeDetailModal() {
  document.getElementById('detailModal').classList.add('hidden');
}

// ================= BACKUP & EXPORT / IMPORT =================
function exportDataJSON() {
  const exportPayload = {
    app: 'adhkar-manager',
    version: '1.0.0',
    exportedAt: new Date().toISOString(),
    categoriesCount: categories.length,
    adhkarCount: adhkar.length,
    categories,
    adhkar
  };

  const dataStr = 'data:text/json;charset=utf-8,' + encodeURIComponent(JSON.stringify(exportPayload, null, 2));
  const downloadAnchor = document.createElement('a');
  downloadAnchor.setAttribute('href', dataStr);
  downloadAnchor.setAttribute('download', `adhkar_backup_${new Date().toISOString().slice(0, 10)}.json`);
  document.body.appendChild(downloadAnchor);
  downloadAnchor.click();
  downloadAnchor.remove();

  showToast('تم تصدير قاعدة بيانات الأذكار بنجاح!');
}

function handleImportFile(event) {
  const file = event.target.files[0];
  if (!file) return;

  const reader = new FileReader();
  reader.onload = function(e) {
    try {
      const parsed = JSON.parse(e.target.result);
      if (Array.isArray(parsed.categories) && Array.isArray(parsed.adhkar)) {
        categories = parsed.categories;
        adhkar = parsed.adhkar;
        saveCategories();
        saveAdhkar();
        showToast(`تم استيراد ${adhkar.length} ذكراً و ${categories.length} تصنيفاً بنجاح!`);
        navigateTo('overview');
      } else {
        alert('صيغة الملف غير متوافقة مع قاعدة بيانات أذكار.');
      }
    } catch (err) {
      alert('خطأ أثناء قراءة ملف JSON: ' + err.message);
    }
  };
  reader.readAsText(file);
}

function confirmResetDefaults() {
  if (confirm('تحذير: هل أنت متأكد من استرجاع البيانات النبوية الأصلية؟ سيتم مسح أي أذكار أو تصنيفات أضفتها يدوياً.')) {
    categories = [...DEFAULT_CATEGORIES];
    adhkar = [...DEFAULT_ADHKAR];
    saveCategories();
    saveAdhkar();
    showToast('تمت استعادة البيانات النموذجية المعتمدة');
    navigateTo('overview');
  }
}

// ================= UTILITIES & HELPERS =================
let toastTimer;
function showToast(msg, icon = 'check_circle') {
  const toast = document.getElementById('toastNotification');
  const msgEl = document.getElementById('toastMessage');
  const iconEl = document.getElementById('toastIcon');

  msgEl.innerText = msg;
  iconEl.innerText = icon;

  toast.classList.remove('translate-y-32', 'opacity-0', 'pointer-events-none');
  toast.classList.add('translate-y-0', 'opacity-100');

  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => {
    hideToast();
  }, 3200);
}

function hideToast() {
  const toast = document.getElementById('toastNotification');
  toast.classList.remove('translate-y-0', 'opacity-100');
  toast.classList.add('translate-y-32', 'opacity-0', 'pointer-events-none');
}

function copyText(text) {
  navigator.clipboard.writeText(text).then(() => {
    showToast('تم نسخ نص الذكر إلى الحافظة');
  }).catch(() => {
    showToast('تعذر النسخ تلقائياً');
  });
}

function copyCurrentDhikrText() {
  const text = document.getElementById('formDhikrText').value;
  copyText(text);
}

function copyDhikrWithSanad(dhikrId) {
  const item = adhkar.find(d => d.id === dhikrId);
  if (!item) return;

  let content = item.text + '\n';
  if (item.repeats > 1) content += `[يُكرر ${item.repeats} مرات]\n`;
  if (item.hadiths && item.hadiths.length > 0) {
    content += '\nالتخريج والمصدر:\n';
    item.hadiths.forEach(h => {
      let line = `• ${h.book || 'مصدر معتمد'}`;
      if (h.number) line += ` (#${h.number})`;
      if (h.grade && h.grade.trim()) line += ` - درجة الصحة: ${h.grade}`;
      content += line + '\n';
      if (h.chapter) content += `  الموضع: ${h.chapter}\n`;
      if (h.text) content += `  متن الحديث: "${h.text}"\n`;
    });
  }

  copyText(content);
}

function escapeHtml(str) {
  return (str || '')
    .replace(/&/g, '&amp;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;');
}

function escapeQuote(str) {
  return (str || '').replace(/'/g, "\\'").replace(/"/g, '&quot;');
}

// ================= DIGITAL MISBAHA (المسبحة الإلكترونية التفاعلية) =================
let misbahaCategoryId = 'morning_evening';
let misbahaDhikrList = [];
let misbahaCurrentIndex = 0;
let misbahaCurrentCount = 0;
let misbahaSessionTotalTaps = 0;
let misbahaSoundEnabled = true;
let misbahaVibrateEnabled = true;
let misbahaIsTransitioning = false;
let audioCtx = null;

function startMisbaha(categoryId) {
  misbahaCategoryId = categoryId || categories[0]?.id || 'morning_evening';
  navigateTo('misbaha', { categoryId: misbahaCategoryId });
}

function initMisbahaSession(catId) {
  if (catId) misbahaCategoryId = catId;
  
  // Populate Category Select Dropdown
  const select = document.getElementById('misbahaCategorySelect');
  if (select) {
    select.innerHTML = '';
    categories.forEach(cat => {
      const opt = document.createElement('option');
      opt.value = cat.id;
      const count = adhkar.filter(d => d.category === cat.id && d.status === 'active').length;
      opt.innerText = `${cat.name} (${count} ذكر)`;
      if (cat.id === misbahaCategoryId) opt.selected = true;
      select.appendChild(opt);
    });
  }

  // Filter adhkar for this category
  misbahaDhikrList = adhkar.filter(d => d.category === misbahaCategoryId && d.status === 'active');
  misbahaCurrentIndex = 0;
  misbahaCurrentCount = 0;
  misbahaSessionTotalTaps = 0;
  misbahaIsTransitioning = false;

  renderMisbahaUI();
}

function handleMisbahaCategoryChange(newCatId) {
  misbahaCategoryId = newCatId;
  initMisbahaSession(newCatId);
}

function renderMisbahaUI() {
  const emptyCard = document.getElementById('misbahaEmptyCard');
  const activeCard = document.getElementById('misbahaActiveCard');
  const compCard = document.getElementById('misbahaCompletionCard');

  if (!activeCard) return;

  if (compCard) compCard.classList.add('hidden');

  if (misbahaDhikrList.length === 0) {
    if (emptyCard) emptyCard.classList.remove('hidden');
    activeCard.classList.add('hidden');
    return;
  }

  if (emptyCard) emptyCard.classList.add('hidden');
  activeCard.classList.remove('hidden');

  renderMisbahaActiveDhikr();
}

function renderMisbahaActiveDhikr() {
  if (misbahaCurrentIndex >= misbahaDhikrList.length) {
    showMisbahaCompletion();
    return;
  }

  const currentDhikr = misbahaDhikrList[misbahaCurrentIndex];
  const cat = categories.find(c => c.id === misbahaCategoryId) || { name: 'الأذكار' };

  // Category Progress Bar & Label
  const progLabel = document.getElementById('misbahaCategoryProgressLabel');
  const progBar = document.getElementById('misbahaCategoryProgressBar');
  if (progLabel) {
    progLabel.innerText = `الذكر ${misbahaCurrentIndex + 1} من ${misbahaDhikrList.length}`;
  }
  if (progBar) {
    const percent = Math.round(((misbahaCurrentIndex) / misbahaDhikrList.length) * 100);
    progBar.style.width = `${Math.max(5, percent)}%`;
  }

  // Badges & Texts
  const catBadge = document.getElementById('misbahaDhikrCatBadge');
  const titleBadge = document.getElementById('misbahaDhikrTitleBadge');
  const repeatsText = document.getElementById('misbahaTargetRepeatsText');
  const dhikrText = document.getElementById('misbahaDhikrText');
  const virtueBox = document.getElementById('misbahaVirtueBox');
  const virtueText = document.getElementById('misbahaVirtueText');
  const sourceBox = document.getElementById('misbahaSourceBox');
  const sourceText = document.getElementById('misbahaSourceText');

  if (catBadge) catBadge.innerText = cat.name;
  if (titleBadge) {
    if (currentDhikr.adminTitle) {
      titleBadge.innerText = currentDhikr.adminTitle;
      titleBadge.classList.remove('hidden');
    } else {
      titleBadge.classList.add('hidden');
    }
  }
  const target = currentDhikr.repeats || 1;
  if (repeatsText) {
    repeatsText.innerText = `المطلوب: ${target} ${target > 2 && target < 11 ? 'مرات' : 'مرة'}`;
  }
  if (dhikrText) {
    dhikrText.innerText = currentDhikr.text;
  }

  // Virtue
  if (virtueBox && virtueText) {
    if (currentDhikr.virtue) {
      virtueText.innerText = currentDhikr.virtue;
      virtueBox.classList.remove('hidden');
    } else {
      virtueBox.classList.add('hidden');
    }
  }

  // Source / Hadith Reference
  if (sourceBox && sourceText) {
    const firstHadith = (currentDhikr.hadiths && currentDhikr.hadiths[0]) ? currentDhikr.hadiths[0] : null;
    if (firstHadith) {
      let str = firstHadith.book || 'مصدر معتمد';
      if (firstHadith.number) str += ` #${firstHadith.number}`;
      if (firstHadith.grade) str += ` (${firstHadith.grade})`;
      sourceText.innerText = str;
      sourceBox.classList.remove('hidden');
    } else {
      sourceBox.classList.add('hidden');
    }
  }

  // Update Misbaha Counter Button
  updateMisbahaCounterVisual();
}

function updateMisbahaCounterVisual() {
  const currentDhikr = misbahaDhikrList[misbahaCurrentIndex];
  if (!currentDhikr) return;

  const target = currentDhikr.repeats || 1;
  const countDisplay = document.getElementById('misbahaCurrentCountDisplay');
  const remainingText = document.getElementById('misbahaRemainingText');
  const progressCircle = document.getElementById('misbahaProgressCircle');

  if (countDisplay) {
    countDisplay.innerText = misbahaCurrentCount;
  }

  if (remainingText) {
    const remaining = Math.max(0, target - misbahaCurrentCount);
    remainingText.innerText = `باقٍ: ${remaining}`;
  }

  if (progressCircle) {
    const circumference = 276.46; // 2 * Math.PI * 44
    const fraction = Math.min(1, misbahaCurrentCount / target);
    const offset = circumference * (1 - fraction);
    progressCircle.style.strokeDashoffset = offset;
  }
}

function handleMisbahaTap() {
  if (misbahaIsTransitioning) return;
  if (misbahaDhikrList.length === 0) return;
  if (misbahaCurrentIndex >= misbahaDhikrList.length) return;

  const currentDhikr = misbahaDhikrList[misbahaCurrentIndex];
  const target = currentDhikr.repeats || 1;

  misbahaCurrentCount++;
  misbahaSessionTotalTaps++;

  playMisbahaClick();
  vibrateMisbaha(25);

  // Button tactile pulse
  const btn = document.getElementById('misbahaTapBtn');
  if (btn) {
    btn.classList.add('scale-95');
    setTimeout(() => btn.classList.remove('scale-95'), 100);
  }

  updateMisbahaCounterVisual();

  // Check if target is achieved
  if (misbahaCurrentCount >= target) {
    playMisbahaComplete();
    vibrateMisbaha([40, 50, 80]);

    if (btn) {
      btn.classList.add('ring-4', 'ring-secondary');
      setTimeout(() => btn.classList.remove('ring-4', 'ring-secondary'), 500);
    }

    // Check if there is a next dhikr
    if (misbahaCurrentIndex < misbahaDhikrList.length - 1) {
      showToast(`تم إتمام هذا الذكر المبارك (${target} مرات)! الانتقال للتالي...`, 'check_circle');
      misbahaIsTransitioning = true;
      setTimeout(() => {
        misbahaCurrentIndex++;
        misbahaCurrentCount = 0;
        misbahaIsTransitioning = false;
        renderMisbahaActiveDhikr();
      }, 450);
    } else {
      // Completed all adhkar in this category!
      misbahaIsTransitioning = true;
      setTimeout(() => {
        misbahaIsTransitioning = false;
        showMisbahaCompletion();
      }, 500);
    }
  }
}

function showMisbahaCompletion() {
  const activeCard = document.getElementById('misbahaActiveCard');
  const compCard = document.getElementById('misbahaCompletionCard');
  const cat = categories.find(c => c.id === misbahaCategoryId) || { name: 'هذا القسم' };

  if (activeCard) activeCard.classList.add('hidden');
  if (compCard) {
    compCard.classList.remove('hidden');
    document.getElementById('misbahaCompletionTitle').innerText = `أتممت ${cat.name} كاملة!`;
    document.getElementById('misbahaSummaryDhikrCount').innerText = `${misbahaDhikrList.length} ذكر`;
    document.getElementById('misbahaSummaryTotalTaps').innerText = `${misbahaSessionTotalTaps} تسبيحة`;
  }

  playMisbahaComplete();
  vibrateMisbaha([60, 60, 100, 60, 150]);
  showToast('هنيئاً لك! أتممت جميع أذكار القسم بنجاح مبارك', 'verified');
}

function nextMisbahaDhikr() {
  if (misbahaCurrentIndex < misbahaDhikrList.length - 1) {
    misbahaCurrentIndex++;
    misbahaCurrentCount = 0;
    renderMisbahaActiveDhikr();
  } else {
    showMisbahaCompletion();
  }
}

function prevMisbahaDhikr() {
  if (misbahaCurrentIndex > 0) {
    misbahaCurrentIndex--;
    misbahaCurrentCount = 0;
    renderMisbahaActiveDhikr();
  }
}

function resetMisbahaCurrentCount() {
  misbahaCurrentCount = 0;
  updateMisbahaCounterVisual();
  showToast('تمت إعادة تصفير عداد الذكر الحالي');
}

function restartCurrentMisbahaCategory() {
  misbahaCurrentIndex = 0;
  misbahaCurrentCount = 0;
  misbahaSessionTotalTaps = 0;
  renderMisbahaUI();
}

function toggleMisbahaSound() {
  misbahaSoundEnabled = !misbahaSoundEnabled;
  const icon = document.getElementById('misbahaAudioIcon');
  if (icon) {
    icon.innerText = misbahaSoundEnabled ? 'volume_up' : 'volume_off';
  }
  showToast(misbahaSoundEnabled ? 'تم تفعيل صوت النقر' : 'تم كتم صوت النقر');
}

function toggleMisbahaVibrate() {
  misbahaVibrateEnabled = !misbahaVibrateEnabled;
  const icon = document.getElementById('misbahaVibrateIcon');
  if (icon) {
    icon.innerText = misbahaVibrateEnabled ? 'vibration' : 'smartphone';
  }
  showToast(misbahaVibrateEnabled ? 'تم تفعيل الاهتزاز' : 'تم إيقاف الاهتزاز');
}

function playMisbahaClick() {
  if (!misbahaSoundEnabled) return;
  try {
    if (!audioCtx) audioCtx = new (window.AudioContext || window.webkitAudioContext)();
    if (audioCtx.state === 'suspended') audioCtx.resume();
    const osc = audioCtx.createOscillator();
    const gain = audioCtx.createGain();
    osc.type = 'sine';
    osc.frequency.setValueAtTime(600, audioCtx.currentTime);
    osc.frequency.exponentialRampToValueAtTime(850, audioCtx.currentTime + 0.04);
    gain.gain.setValueAtTime(0.12, audioCtx.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.001, audioCtx.currentTime + 0.04);
    osc.connect(gain);
    gain.connect(audioCtx.destination);
    osc.start();
    osc.stop(audioCtx.currentTime + 0.04);
  } catch (e) {}
}

function playMisbahaComplete() {
  if (!misbahaSoundEnabled) return;
  try {
    if (!audioCtx) audioCtx = new (window.AudioContext || window.webkitAudioContext)();
    if (audioCtx.state === 'suspended') audioCtx.resume();
    const now = audioCtx.currentTime;
    [523.25, 659.25, 783.99, 1046.5].forEach((freq, i) => {
      const osc = audioCtx.createOscillator();
      const gain = audioCtx.createGain();
      osc.type = 'triangle';
      osc.frequency.setValueAtTime(freq, now + i * 0.07);
      gain.gain.setValueAtTime(0.18, now + i * 0.07);
      gain.gain.exponentialRampToValueAtTime(0.001, now + i * 0.07 + 0.22);
      osc.connect(gain);
      gain.connect(audioCtx.destination);
      osc.start(now + i * 0.07);
      osc.stop(now + i * 0.07 + 0.22);
    });
  } catch (e) {}
}

function vibrateMisbaha(pattern) {
  if (!misbahaVibrateEnabled) return;
  if ('vibrate' in navigator) {
    try {
      navigator.vibrate(pattern);
    } catch (e) {}
  }
}

// Spacebar shortcut for Misbaha
window.addEventListener('keydown', (e) => {
  if (e.code === 'Space' || e.key === ' ') {
    const misbahaView = document.getElementById('viewMisbaha');
    if (misbahaView && !misbahaView.classList.contains('hidden')) {
      e.preventDefault();
      handleMisbahaTap();
    }
  }
});

// ================= INITIAL RUN =================
document.addEventListener('DOMContentLoaded', () => {
  initStorage();

  const hash = window.location.hash.replace('#', '');
  if (SECTIONS.includes(hash)) {
    navigateTo(hash);
  } else {
    navigateTo('overview');
  }
});
