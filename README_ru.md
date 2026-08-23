<div align="center">
  <h1>🚀 ZCode Mobile</h1>

  <p>
    <strong>Высокопроизводительный полноэкранный графический интерфейс для ZCode IDE на Android.</strong>
  </p>

  <p>
    <strong>🇷🇺 Русский</strong> | 
    <a href="README.md">🇬🇧 English</a>
  </p>

  <p>
    <img alt="Версия" src="https://img.shields.io/badge/версия-1.0.0-blue.svg?cacheSeconds=2592000" />
    <img alt="Платформа" src="https://img.shields.io/badge/платформа-Termux%20X11-lightgrey" />
    <img alt="GPU" src="https://img.shields.io/badge/ускорение-Turnip%20%7C%20Zink-success" />
    <img alt="Лицензия" src="https://img.shields.io/badge/лицензия-MIT-green" />
  </p>
</div>

---

## ⚡ Быстрая установка

**Предварительные требования:** Убедитесь, что у вас установлено приложение [Termux-X11 APK](https://github.com/termux/termux-x11/releases) на устройстве.

Скопируйте и выполните следующую команду в терминале Termux для установки или обновления ZCode Mobile:

```bash
curl -sL https://raw.githubusercontent.com/zenyxx-xd/ZCode-Mobile/main/install.sh | bash
```

> **Примечание:** Скрипт автоматически настроит подсистему Debian, драйверы аппаратного ускорения Turnip/Zink и установит готовый лаунчер.

---

## 🌟 Основные возможности

* **🖥️ Полноэкранный режим (Kiosk Mode):** Запуск без рамок и заголовков окон через Matchbox Window Manager для максимального погружения в работу.
* **⚡ Аппаратное GPU-ускорение:** Полная интеграция драйверов Mesa Turnip + Zink, многопоточный рендеринг (`MESA_GLTHREAD`), zero-copy буферы и аппаратная растеризация 2D Canvas.
* **🔑 Удобная OAuth-авторизация:** Автоматическое определение статуса входа. Если вы не вошли, достаточно нажать клавишу `[A]` в терминале — ссылка обратного вызова будет скопирована из буфера Android автоматически.
* **🔄 Нативное автообновление:** Встроенный мост `pkexec` позволяет применять обновления прямо из интерфейса приложения («Restart to update») без ручных действий.
* **📱 Оптимизированный масштаб для смартфонов (2.5x):** Идеально сбалансированный масштаб интерфейса Electron, системных диалогов GTK-3.0 и шрифтов X11 для экранов с высокой плотностью пикселей.
* **🌐 Мгновенное открытие ссылок в Android:** Клик по ссылкам и кнопкам авторизации моментально открывает мобильный браузер через системный Activity Manager.
* **🔄 Единый профиль:** Общее хранилище сессий, настроек и расширений как при запуске из хоста Termux, так и внутри Debian PRoot.

---

## 🚀 Запуск и управление

После завершения установки запустите среду разработки:

```bash
zcode
```

### Параметры командной строки

| Флаг | Описание |
| :--- | :--- |
| `zcode` | Запуск ZCode IDE в полноэкранном режиме |
| `zcode --debug` | Запуск в консольном режиме с подробными логами Electron |
| `zcode --software` | Запуск в режиме программного рендеринга (LLVMpipe) |
| `zcode --full-delete` | Полное удаление ZCode IDE и его конфигурации |
| `zcode --proot-reset` | Сброс контейнера Debian PRoot |

---

## 📱 Системные требования

* **ОС Android:** Android 10 или новее (ARM64 / x86_64)
* **Приложение Termux:** [F-Droid](https://f-droid.org/en/packages/com.termux/) или [GitHub Releases](https://github.com/termux/termux-app/releases)
* **Приложение Termux:X11:** [GitHub Releases](https://github.com/termux/termux-x11/releases)
* **Память:** Не менее 2.5 ГБ свободного места на устройстве

---

## 📄 Лицензия

Проект распространяется под лицензией [MIT](LICENSE).
