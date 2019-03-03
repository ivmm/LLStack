# 什么是 LLStack ？

LLStack 全称是 “Linux LiteSpeed Stack”，即在 Linux 上安装 LiteSpeed + PHP + MySQL/MariaDB（可选）的高性能 Web 运行环境，特别适合运行 PHP 程序。

更多具体稳定和安装教程请看：https://www.llstack.com/

# LiteSpeed 介绍

LiteSpeed 即 LiteSpeed Web Server（简称 LSWS），是一款企业级商用 Web 服务软件，可以完美的 Apache HTTPD 兼容体验，.htaccess 规则可以直接兼容而不像 Nginx 需要重写，并兼容常用的mod扩展。得益于基于事件的架构优势，静态内容比Apache Httpd 快 5 倍 ，动态内容更是快 40 倍，HTTPS 访问快 3 倍并可以应用硬件加速器。

同时作为商业 Web 服务软件，也率先研究并落地最新的 Web 技术，在 HTTP/2 和 HTTP/3（QUIC） 上均是第一个应用的 Web 服务软件，可以直接无缝使用 Brotli、LSCahe 等新特性而无需像 Nginx 一样需要额外配置非官方的扩展并担心 API 兼容性问题。

## LiteSpeed 特性

### 更高性能

LiteSpeed Web Server使用事件驱动的体系结构，Apache是基于流程的。LiteSpeed Web Server及其事件驱动架构，可为几乎没有进程的所有连接提供服务，从而节省资源。

### 更加安全

同时 LiteSpeed 也支持 mod_Security，可以轻松实现基础的 WAF 能力，在没有极高的防御需求的时候仅使用 LiteSpeed 则无需额外购买高昂的商业WAF。 同时针对一些 CC 和 DDOS 攻击，LiteSpeed 也有做好优化和应对策略，可以降低攻击造成的影响。

### 开箱即用

相比 Nginx、Apache 安装一些高性能扩展，如 PageSpeed，Brotli，或者和 Varnish 这样的内存级 Web 加速软件，一些协议的支持上如TLS 1.3、QUIC，搭配都需要一定的经验以及复杂的配置，而这些特性在 LiteSpeed 上都是开箱即用的。

### 可视化后台

不同于 Nginx、Apache HTTPD 黑底白字的配置文件，LiteSpeed 即可以通过编辑配置文件操作也可以通过可视化控制台进行操作，降低操作门槛。

### Apache 兼容

不仅仅是兼容 Apache HTTPD 的特性和扩展，LiteSpeed 可以直接读取 Apache HTTPD 配置文件并转化，并且在不停机条件下直接从 Apache HTTPD 上完成无缝迁移。

**更多特性和 LiteSpeed 介绍请看：**  [LiteSpeed 介绍页](https://www.llstack.com/zh/LiteSpeed/)

# 安装

**注意**

LLStack 仅适用于 RHEL 7 系操作系统及其衍生版，RHEL7、CentOS7、OracleLinux7、CloudLinux 7等。 RHEL 8 系正在测试中。

**安全组/防火墙**

安装前务必要根据教程开启服务器安全组和防火墙中LLStack所依赖的端口。 教程： [**安全组设置**](https://www.llstack.com/zh/others/Security-group.html)

安装完 LLStack 后防火墙的设置请参考： [**安全组设置**](https://www.llstack.com/zh/others/firewall.html)

## 轻量版

LLStack 轻量版脚本只提供 LiteSpeed 的图形化面板，其他 PHP、MySQL（MariaDB）的管理全部使用软件默认的配置文件，配置较为复杂，适合有经验高手和不习惯面板的同学使用。当然，也会更加简洁高效，同时资源利用率和安全性也更高。

**安装脚本：**

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ivmm/LLStack/master/install.sh)" 2>&1 | tee llstack-all.log
```

[轻量版详细教程 →](https://www.llstack.com/zh/Lite/)

## 面板版

面板版是深度集成了非常好用且Web应用非强制性的 APPNode 面板而来的版本，常见的服务器组件如 PHP、MySQL、Redis、Memcached 都提供了图形化支持，同时也提供软件管家、防火墙、文件管理、备份管理等众多实用功能，适合新手使用，也适合有大量服务器运维的同学使用。

**安装脚本：**

```bash
INSTALL_AGENT=1 INIT_SWAPFILE=1 INSTALL_PKGS='php73' bash -c "$(curl -sS http://dl.appnode.com/install.sh)"
yum install appnode-app-mysqld appnode-app-php
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ivmm/LLStack/master/install-appnode.sh)" 2>&1 | tee llstack-all.log
```

[面板版详细教程 →](https://www.llstack.com/zh/panel/)

