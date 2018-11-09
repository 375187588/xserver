package main

import(
    "fmt"
//    "encoding/json"
    "bytes"
    "net/http"
    "io/ioutil"
    "time"
)

func heartbeat(){
    for {
        select {
        case <-time.After(time.Second * 5):
            go sendHeartbeat()
        }
    }
}

func sendHeartbeat(){
    req := bytes.NewBuffer([]byte(h.Heartbeat))
    body_type := "application/json;charset=utf-8"
    resp, _ := http.Post(h.HeartbeatUrl, body_type, req)
    if resp != nil {
        body, _ := ioutil.ReadAll(resp.Body)
        fmt.Println(string(body))
    }
}
