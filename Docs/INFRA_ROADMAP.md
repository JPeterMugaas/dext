# 🏗️ Dext Infrastructure - Roadmap

Este documento centraliza o desenvolvimento da infraestrutura de baixo nível do framework, com foco em **Performance Extrema** e **Eficiência de Recursos**.

> **Visão:** Prover uma fundação sólida, "Metal-to-the-Pedal", que permita ao Dext competir em performance com frameworks Go, Rust e .NET (Kestrel).

---

## 🚀 High Performance HTTP Server (Clean Room Implementation)

Reescrita do núcleo HTTP para eliminar gargalos de arquiteturas legadas (Indy/WebBroker) e explorar recursos nativos do SO.

### 1. Windows: Kernel Mode (`http.sys`)
Integração direta com o driver `http.sys` do Windows (mesma stack do IIS e Kestrel).
- [ ] **Native API Binding**: Importação da `httpapi.dll` (HttpInitialize, HttpCreateHttpHandle).
- [ ] **Zero-Copy**: Utilizar buffers do kernel para evitar cópias desnecessárias de memória.
- [ ] **Kernel-Mode Caching**: Servir arquivos estáticos e respostas cacheadas diretamente do Kernel.
- [ ] **Port Sharing**: Permitir compartilhar a porta 80/443 com IIS e outras apps.
- [ ] **HTTP/3 (QUIC)**: Suporte experimental ao novo protocolo HTTP sobre UDP para performance em redes instáveis.

### 2. Linux: Event-Driven I/O (`epoll`)
Modelo não-bloqueante para alta concorrência no Linux.
- [ ] **Epoll Integration**: Uso de `epoll_create1`, `epoll_ctl`, `epoll_wait`.
- [ ] **Thread Pool**: Workers fixos (CPU Bound) processando eventos de I/O de milhares de conexões.
- [ ] **Non-Blocking Sockets**: Eliminar o modelo "Thread-per-Connection".

### 3. Memory & String Optimization (Zero-Allocation)
Eliminar o custo de conversão `UTF-8` <-> `UTF-16` (UnicodeString) no core do framework.
- [ ] **RawUTF8 / Span<byte>**: Tipo de dados base para manipulação de strings sem conversão.
- [ ] **Zero-Allocation Parsing**: Roteamento e Headers processados varrendo bytes diretamente.
- [ ] **UTF-8 JSON Parser**: Novo parser JSON otimizado para ler/escrever UTF-8 diretamente, sem alocações intermediárias de strings Delphi.

---

## 🛠️ Core Infrastructure

### 1. Telemetry & Observability Foundation
Base para o suporte a OpenTelemetry nos frameworks superiores.
- [ ] **Activity/Span API**: Abstração para rastreamento distribuído.
- [ ] **Metrics API**: Contadores, Histogramas e Gauges de alta performance.
- [ ] **Logging Abstraction**: Zero-allocation logging interface.

### 2. Async/Await Foundation
- [ ] **Fluent Tasks API**: Primitivas para orquestração de tarefas assíncronas.
- [ ] **Scheduler**: Scheduler customizado para otimizar context switches em operações de I/O.
