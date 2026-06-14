# Getting Started with InkRoot

Welcome! This guide will help you get up and running with InkRoot in just a few minutes.

---

## 📥 Installation

### iOS

1. Download from [GitHub Releases](https://github.com/yyyyymmmmm/InkRoot/releases)
2. Install via TestFlight or sideload IPA
3. Launch InkRoot

### Android

1. Download APK from [GitHub Releases](https://github.com/yyyyymmmmm/InkRoot/releases)
2. Enable "Install from Unknown Sources" if prompted
3. Install and open InkRoot

---

## 🚀 First Launch

### 1. Welcome Screen

When you first open InkRoot, you'll see the welcome screen with two options:

#### Option A: Local Mode (Recommended for Beginners)
- ✅ No setup required
- ✅ All data stored on your device
- ✅ Perfect for personal use

**Choose this if:**
- You want to start immediately
- You don't need multi-device sync
- You value privacy and offline access

#### Option B: Cloud Sync Mode
- Requires Memos server
- Syncs across devices
- Great for teams

**Choose this if:**
- You have a Memos server
- You need multi-device access
- You want backup in the cloud

### 2. Privacy Policy

Read and accept the privacy policy to continue.

### 3. Grant Permissions (When Needed)

InkRoot may request permissions for:
- 🎤 **Microphone**: For voice input
- 📷 **Camera**: For taking photos
- 🖼️ **Photos**: For uploading images
- 🔔 **Notifications**: For reminders

*You can grant these later when you use the features.*

---

## 📝 Creating Your First Note

### Step 1: Tap the + Button

Look for the floating **+** button at the bottom of the screen.

### Step 2: Write Your Note

```markdown
# My First Note

This is my first note in InkRoot!

I can use **bold** and *italic* text.

- [ ] Try voice input
- [ ] Add an image
- [ ] Create a tag
```

### Step 3: Add Tags

Tags help organize your notes. Add them at the end:

```markdown
#getting-started #important
```

### Step 4: Save

Notes save automatically! Tap the back arrow to return to the list.

---

## 🎯 Essential Features

### Voice Input 🎤

1. Tap the microphone icon in the editor
2. Speak clearly
3. Your speech converts to text automatically
4. Edit as needed

**Tips:**
- Use in quiet environments for best results
- Speak naturally, don't rush
- Works in Chinese and English

### Todo Lists ✅

Create interactive todo lists:

```markdown
- [ ] Incomplete task
- [x] Completed task
- [ ] Another task
```

**Tap the checkbox** to toggle completion status!

### Adding Images 📷

1. Tap the camera icon in the editor
2. Choose:
   - 📷 Take Photo
   - 🖼️ Choose from Gallery
3. Image uploads automatically
4. Long press any image to save it

### Tags 🏷️

Organize with tags:

```markdown
#work #personal #ideas #urgent
```

- Tap a tag to see all notes with that tag
- View all tags in Settings → Tags

### Search 🔍

1. Tap the search icon (🔍)
2. Type your query
3. Search across:
   - Note titles
   - Note content
   - Tags

---

## 🎨 Customizing InkRoot

### Change Theme

**Settings → Preferences → Appearance**

- ☀️ Light Mode
- 🌙 Dark Mode
- 🔄 Auto (Follow System)

### Change Font

**Settings → Preferences → Font**

**Sizes:**
- Small
- Standard (default)
- Large
- Extra Large

**Fonts:**
- SF Pro Display
- Source Han Sans
- Source Han Serif
- Kaiti Style
- Zcool XiaoWei
- Zcool QingKe

### Change Language

**Settings → Preferences → Language**

- 🇨🇳 Chinese
- 🇺🇸 English

---

## ☁️ Setting Up Cloud Sync (Optional)

If you chose Cloud Sync Mode or want to enable it later:

### Step 1: Deploy Memos Server

**Option A: Docker (Recommended)**
```bash
docker run -d \
  --name memos \
  --publish 5230:5230 \
  --volume ~/.memos/:/var/opt/memos \
  neosmemo/memos:latest
```

**Option B: Use Demo Server**
- Server: `https://memos.didichou.site`
- *For testing only, data may be cleared*

### Step 2: Configure InkRoot

1. Open **Settings → Server Info**
2. Enter server address:
   ```
   http://your-server:5230
   ```
   or
   ```
   https://your-domain.com
   ```
3. Tap **Save**

### Step 3: Create Account or Login

1. Tap **Register** for new account
2. Or **Login** with existing credentials
3. Enter username and password
4. Tap **Sign In**

### Step 4: First Sync

- Notes sync automatically
- Pull down to refresh manually
- Check sync status in Settings

---

## 📚 Next Steps

Now that you're set up, explore these features:

### Week 1: Basics
- [ ] Create 5-10 notes
- [ ] Try voice input
- [ ] Add images to notes
- [ ] Organize with tags
- [ ] Use todo lists

### Week 2: Organization
- [ ] Try search function
- [ ] Pin important notes
- [ ] Set up reminders
- [ ] Explore settings

### Week 3: Advanced
- [ ] Create note references `[[Title]]`
- [ ] View knowledge graph
- [ ] Try AI assistant
- [ ] Export notes for backup

---

## 💡 Quick Tips

### Writing Efficiently
- Use voice input for quick capture
- Create note templates for common formats
- Use consistent tag system
- Pin frequently accessed notes

### Staying Organized
- Review notes weekly
- Archive completed tasks
- Use descriptive titles
- Add relevant tags

### Data Safety
- Export notes regularly (Settings → Import/Export)
- Keep backups of important notes
- Test cloud sync if enabled

---

## 🆘 Having Issues?

### Common Issues

**Can't save notes?**
- Check storage space on device
- Try restarting the app
- Check permissions

**Voice input not working?**
- Grant microphone permission
- Check device microphone
- Try in quiet environment

**Sync not working?**
- Check internet connection
- Verify server address
- Check Memos server status
- Use a supported Memos server; InkRoot detects v0.21.x to v0.28.x API differences

**Images not loading?**
- Check storage space
- Grant photo permissions
- Restart app

### Get Help
- 📖 Read [FAQ](faq.md)
- 🔧 Check [Troubleshooting](troubleshooting.md)
- 📧 Email: inkroot2025@gmail.com
- 💬 GitHub: [Discussions](https://github.com/yyyyymmmmm/InkRoot/discussions)

---

## 📖 Learn More

Ready to dive deeper? Check out:

- [Markdown Guide](features/markdown.md) - Master Markdown syntax
- [Todo Lists](features/todo-lists.md) - Advanced task management
- [Knowledge Graph](features/knowledge-graph.md) - Visualize connections
- [AI Assistant](features/ai-assistant.md) - Smart writing help

---

<div align="center">

**You're all set!** 🎉

Start writing amazing notes with InkRoot.

[View All Features](README.md) | [FAQ](faq.md) | [Get Support](support.md)

</div>

