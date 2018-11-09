package main

import(
    "net"
    "fmt"
    "time"
    "hash/crc32"
    "io"
    "crypto/md5"
    "encoding/hex"
)

type Bridge struct {
    local net.Conn
    remote net.Conn
    buf []byte
    buf_i uint
    index uint
    ip string
    last_time int64
    last_count uint
}

func (this *Bridge) Init() {
    this.buf = make([]byte, 1024, 1024)
    this.buf_i = 0
    this.last_time = 0
    this.last_count = 0
    this.index = 1
}

func (this *Bridge) SetLocal(conn net.Conn, ip string) {
    this.local = conn
    this.ip = ip
}

func (this *Bridge) CheckFrequency() bool {
    now := time.Now().Unix()
    if(now/60 == this.last_time/60) {
        this.last_count++
        fmt.Println("frequency",this.last_count)
        if this.last_count > uint(cfg.PackFrequncy) {
            server.AddBlackIP(this.ip)
            fmt.Println("发包频率过快, 加入黑名单",this.ip)
            return false
        }
    } else {
        this.last_time = now
        this.last_count = 1
    }

    return true
}

func (this *Bridge) Start() {
    defer this.Close()

    if !this.readHostPack() {
        return
    }

    ret, host := this.getHost()
    if !ret {
        server.AddBlackIP(this.ip)
        return
    }

    if !this.readFirstPack() {
        fmt.Println("读取第一个包失败", this.ip)
        server.AddEmptyLink(this.ip)
        return
    }

    check, n := this.CheckPack()
    if !check || n == 0 {
        fmt.Println("检测第一个包失败", this.ip)
        server.AddBlackIP(this.ip)
        return
    }
    if !this.ConnRemote(host) {
        fmt.Println("链接服务器失败")
        return
    }
    this.Pipe()
}

func (this *Bridge) ConnRemote(host string) bool {
    s, err := net.ResolveTCPAddr("tcp", host)
    conn, err := net.DialTCP("tcp", nil, s)
    if err != nil {
        fmt.Println("ERROR: Dial failed:", err.Error())
        return false
    }
    this.remote = conn
    // 第一个包发送给服务器
    this.remote.Write(this.buf[:this.buf_i])
    this.buf_i = 0
    fmt.Println("链接服务器，客户端ip",this.ip)
    return true
}

func (this *Bridge) readHostPack() bool {
    this.local.SetReadDeadline(time.Now().Add(time.Duration(10) * time.Second))
    n, err := this.local.Read(this.buf[:])
    if err != nil || n == 0{
        server.AddEmptyLink(this.ip)
        fmt.Println("readHostPack出错", n, err)
        return false
    }
    this.buf_i = (uint)(n)
    return true
}

func (this *Bridge) getHost() (bool, string) {
    if this.buf_i <= 32 {
        fmt.Println("getHost error: 包长不够")
        return false, ""
    }

    n := (uint)(this.buf[0])*256 + (uint)(this.buf[1])
    if n > uint(cfg.MaxLen) {
        fmt.Println("getHost error: 包体太大")
        return false, ""
    }

    if n + 2 > this.buf_i {
        fmt.Println("getHost error: 包体不全")
        return false, ""
    }

    data := this.buf[2:n+2]

    l := len(data)
    str := data[0:l-32]
    sign := string(data[l-32:])

    md5ctx := md5.New()
    md5ctx.Write(str)
    md5ctx.Write([]byte("hello"))
    sum := hex.EncodeToString(md5ctx.Sum(nil))
    if sign != sum {
        fmt.Println("md5校验失败")
        return false, ""
    }

    buf := make([]byte, len(str)/2)
    _, err := hex.Decode(buf, str)
    if err != nil {
        return false, ""
    }

    host := make([]byte, len(buf))
    key := []byte("uhel")
    for i:=0; i < len(buf); i++{
        temp := buf[i] ^ key[0]
        for j:=1;j<len(key);j++ {
            temp = temp ^ key[j]
        }
        host[i] = temp
    }

    for i:=uint(0);i<this.buf_i-n-2;i++{
        this.buf[i] = this.buf[i+n+2]
    }
    this.buf_i -= (n+2)
    return true, string(host)
}

func (this *Bridge) readFirstPack() bool {
    if this.buf_i >= 2 {
         n := (uint)(this.buf[0])*256 + (uint)(this.buf[1])
         if n + 2 <= this.buf_i {
            this.local.SetReadDeadline(time.Time{})
            return true
         }
         fmt.Print("readFirstPack剩余包头",n)
    }

    n, err := this.local.Read(this.buf[this.buf_i:])
    if err != nil || n == 0{
        server.AddEmptyLink(this.ip)
        fmt.Println(n, err)
        return false
    }
    this.buf_i += (uint)(n)
    this.local.SetReadDeadline(time.Time{})
    return true
}

func (this *Bridge) CheckPack() (bool, uint) {
    start := uint(0)
    for {
        check,n := this.CheckOnePack(start)
        fmt.Println(check, n)
        if !check {
            return false,0
        }
        if n <= 0 {
            return true, start
        }
        start += n
        if start == this.buf_i {
            break
        }
    }

    return true, start
}

func (this *Bridge) AddData(data []byte) bool{
    n := uint(len(data))
    if this.buf_i + n > 1024 {
        server.AddBlackIP(this.ip)
        return false
    }

    for i:=uint(0);i<n;i++{
        this.buf[this.buf_i + i] = data[i]
    }

    this.buf_i += n
    return true
}

func (this *Bridge) CheckOnePack(start uint) (bool, uint) {
    if this.buf_i <= start + 2 {
        return false, 0
    }

    n := (uint)(this.buf[start + 0])*256 + (uint)(this.buf[start + 1])
    if n > uint(cfg.MaxLen) {
        return false, 0
    }

    if n + 2 > uint(this.buf_i) {
        return true, 0
    }

    // 检查发包频率
    if !this.CheckFrequency() {
        return false, 0
    }

    // 检查包体内容是否合法
    if !this.CheckOnePackData(start+2, n) {
        return false, 0
    }

    this.index = this.index + 1
    return true, uint(n+2)
}

func (this *Bridge) CheckOnePackData(start uint, n uint) bool {
    buf := xor(this.buf[start:start+n], n)
    protoid := (uint)(buf[0])*256 + (uint)(buf[1])
    index := (uint)(buf[n - 10])*256 + (uint)(buf[n - 9])

    fmt.Println(this.ip,"protoid",protoid,"index",index)
    if 0 == protoid {
        return false
    }

   if index != this.index {
        fmt.Println("包序号校验失败", index)
        return false
    }
    sum := string(buf[n - 8:])
    _ = sum
    ieee := crc32.NewIEEE()
    io.WriteString(ieee, string(buf[0:n-8]))
    s := ieee.Sum32()
    ssum := fmt.Sprintf("%08x", s)
    if sum != ssum {
        fmt.Println("包crc32校验失败")
        return false
    }

    return true
}

func (this *Bridge) Pipe() {
    local_chan := ChanFromConn(this.local)
    remote_chan := ChanFromConn(this.remote)
    for {
        select {
        case b1 := <-local_chan:
            if b1 == nil {
                fmt.Println("客户端断开连接")
                return
            }
            if !this.AddData(b1) {
                return
            }
            check,n := this.CheckPack()
            if !check {
                server.AddBlackIP(this.ip)
                fmt.Println("检查客户端包失败", this.ip)
                return
            }
            if n > 0 {
                this.remote.Write(this.buf[:n])
                for i:=uint(0); i<this.buf_i-n;i++{
                    this.buf[i] = this.buf[n+i]
                }
                this.buf_i -= n
            }
        case b2 := <-remote_chan:
            if b2 == nil {
                fmt.Println("服务器关闭连接")
                return
            }
            this.local.Write(b2)
        }
    }
}

func (this *Bridge) Close() {
    fmt.Println("关闭桥", this.ip)
    if this.local != nil {
        this.local.Close()
        this.local = nil
    }

    if this.remote != nil {
        this.remote.Close()
        this.remote = nil
    }
}
