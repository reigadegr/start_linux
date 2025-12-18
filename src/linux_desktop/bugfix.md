# Linux桌面端小bug修复
记录一下遇到的一些小bug解决方案

## 解决edge打不开等问题

> 常见于更改hostname

```bash
rm -f ~/.config/microsoft-edge*/SingletonLock
rm -f ~/.config/microsoft-edge*/SingletonCookie
```
