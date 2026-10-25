#!/usr/bin/env python3
"""Generate editable store-copy drafts from the reviewed app string catalog."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
catalog = json.loads((ROOT / 'KeepAwake/Localizable.xcstrings').read_text())['strings']
metadata = {
    'en': ('en-US', 'Keep your Mac awake', 'sleep,display,screen,utility,menubar,work'),
    'zh-Hans': ('zh-Hans', '轻量菜单栏防休眠工具', '防休眠,屏幕常亮,菜单栏,效率,工作'),
    'zh-Hant': ('zh-Hant', '輕量選單列防睡眠工具', '防睡眠,螢幕常亮,選單列,效率,工作'),
    'ja': ('ja', 'Mac のスリープを手軽に防止', 'スリープ,画面,作業,メニューバー'),
    'ko': ('ko', 'Mac을 깨어 있게 유지하세요', '잠자기,화면,메뉴막대,작업,유틸리티'),
    'de': ('de-DE', 'Deinen Mac wach halten', 'ruhezustand,display,bildschirm,menüleiste,arbeit'),
    'fr': ('fr-FR', 'Gardez votre Mac éveillé', 'veille,écran,utilitaire,menus,travail'),
    'es': ('es-ES', 'Mantén tu Mac despierto', 'reposo,pantalla,utilidad,menú,trabajo'),
    'pt-BR': ('pt-BR', 'Mantenha seu Mac desperto', 'repouso,tela,utilitário,menu,trabalho'),
    'ru': ('ru', 'Не давайте Mac заснуть', 'сон,экран,работа,меню,утилита'),
    'it': ('it', 'Mantieni attivo il tuo Mac', 'stop,schermo,utility,menu,lavoro'),
}
paragraphs = [
    'A small menu bar utility that keeps your Mac awake during long tasks.',
    'Left-click the menu bar cup to toggle Keep Awake. Right-click or Control-click to open the menu.',
    'Keep Display Awake also prevents idle display sleep. Turn it off to let the display sleep while the Mac stays awake.',
    'System sleep ends the current session. After waking, turn Keep Awake on again when needed. Launch at login never starts a session automatically.',
    'Keep Awake does not prevent manual sleep or manual locking, unlock your Mac, or guarantee operation with the lid closed. System and organization security policies still apply.',
    'One purchase. All features. No subscription or in-app purchases.',
    'Keep Awake works locally without an account. The app does not send personal data, usage analytics, or advertising identifiers to the developer.',
]
entries = {}
for language, (apple_locale, subtitle, keywords) in metadata.items():
    description = '\n\n'.join(catalog[key]['localizations'][language]['stringUnit']['value'] for key in paragraphs)
    entries[language] = dict(appleLocale=apple_locale, name='Keep Awake', subtitle=subtitle, keywords=keywords, description=description)
output = ROOT / 'docs/app-store/localizations.json'
output.write_text(json.dumps({'status': 'DRAFT — verify name availability and obtain native-language review before publishing', 'localizations': entries}, ensure_ascii=False, indent=2)+'\n')
print(f'Prepared {len(entries)} store localization drafts: {output.relative_to(ROOT)}')
