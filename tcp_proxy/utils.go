package main

import(
    "net"
    "fmt"
)

func ChanFromConn(conn net.Conn) chan []byte {
    c := make(chan []byte)
    go func() {
        b := make([]byte, 1024)
        for {
            if n, err := conn.Read(b); err != nil {
                c <- nil
                break
            } else if n > 0 {
                res := make([]byte, n)
                copy(res, b[:n])
                c <- res
            }
        }
    }()
    return c
}

func xor(data []byte, n uint) []byte{
    buf := make([]byte, n)
    fmt.Println(data)
    key := []byte("cigam")
    fmt.Println("n=",n,"key len=",len(key))
    for i:=uint(0);i<n;i++{
        temp := data[i] ^ key[0]
        for j:=1;j<len(key);j++ {
            temp = temp ^ key[j]
        }
        buf[i] = temp
    }
    fmt.Println(buf)
    return buf
}
