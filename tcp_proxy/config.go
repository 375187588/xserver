package main

import (
    "encoding/json"
    "os"
    "fmt"
)

type Config struct {
    Laddress string     `json:"Laddress"`
    MaxLen int          `json:"MaxLen"`
    PackFrequncy int    `json:"PackFrequncy"`
    HeartbeatUrl string `json:"heartbeat_url"`
    Heartbeat string    `json:"heartbeat"`
}

var cfg *Config = &Config{
  Laddress:":3000",             // 本地监听端口
  MaxLen: 512,                  // 最大包长
  PackFrequncy: 3,              // 每分钟发包频率
  HeartbeatUrl: "",
  Heartbeat: "",

}

func LoadCfg(path string) {
    file, err := os.Open(path)
    if err != nil {
        panic("fail to read config file: " + path)
        return
    }

    defer file.Close()

    fi, _ := file.Stat()

    buff := make([]byte, fi.Size())
    _, err = file.Read(buff)
    buff = []byte(os.ExpandEnv(string(buff)))

    err = json.Unmarshal(buff, cfg)
    if err != nil {
        panic("failed to unmarshal file")
        return
    }
    fmt.Println("read cfg success", cfg)
}

