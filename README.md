# Probiform Game

**Data Sedimentation — Constructing a Probabilistic Body**

*Machine Inference and the Probabilistic Body* is an interactive installation that explores how machines construct representations of human presence from fragmented and incomplete information.

Instead, the system uses a low-resolution non-visual sensing network consisting of ultrasonic sensors, sound sensors, and millimeter-wave radar. These sensors can only detect partial signals such as distance, sound, and movement. Through continuous accumulation, interpretation, filtering, and misinterpretation of these signals, the system gradually constructs a machine-readable representation of human presence, which I describe as a Probabilistic Body.

Participants interact with the installation through movement and sound. Distance data influences the spatial behaviour of falling data blocks, while sound affects the machine’s confidence in the information it receives. The machine simultaneously listens to both human-generated sounds and sounds produced by its own electronic components, creating a feedback loop between human and machine perception.

项目包含两部分：

- `WSAA2_06/`：Processing 主程序，负责视觉、交互逻辑、声音、OSC
- `Arduino_Probiform_Printer_Bridge/`：Arduino Mega 2560 固件，负责采集传感器、驱动双 LCD、控制 LD2410，并通过 USB 串口与 Processing 通信。

## 视觉表达 / Visual Language

Tetris functions as a visual language of data sedimentation rather than a representation of the body itself. Each block represents a fragment of information received by the machine at a particular moment. As data accumulates over time, these fragments gradually form a larger structure, revealing how technical systems construct and organise representations from incomplete evidence.

### PMSD Tetris Form Library / PMSD 俄罗斯方块形态库

The following forms were designed for the active PMSD states currently used by the installation. Each four-bit label corresponds to **Presence, Motion, Sound, and Distance**. Rather than using conventional Tetris pieces, the project translates different combinations of sensed information into a custom machine-like form. These forms fall, rotate, overlap, and accumulate to construct the evolving probabilistic body.

以下形态由作者为装置当前使用的 PMSD 活跃状态设计。每个四位编码依次对应 **Presence（存在）、Motion（运动）、Sound（声音）和 Distance（距离）**。项目并未直接采用传统俄罗斯方块，而是将不同的传感信息组合转化为自定义的机器形态；这些形态通过下落、旋转、重叠与沉积，逐渐构成持续变化的“概率性身体”。

![Custom PMSD Tetris form library showing the states 1000 to 1111](output/pmsd-shape-library.png)

## 功能

- 将 Presence、Motion、Sound、Distance 组合为 4-bit PMSD 数据
- 根据传感器数据生成、旋转和沉积图形
- 显示 Win95 风格的实时数据界面
- 根据系统状态合成机器声景
- 通过 OSC 向 Max/MSP 输出实时参数
- 每沉积 15 个数据块自动生成一张 192 × 128 的热敏打印图像
- 无 Arduino 时可使用键盘测试模式运行
- 无人参与时自动进入推断与循环展示状态

## 环境要求

### Processing

- Processing 4
- Sound 库
- oscP5 库
- Serial 库（Processing 自带）

在 Processing IDE 中通过 **Sketch → Import Library → Manage Libraries…** 安装缺少的库。

### Arduino

- Arduino Mega 2560
- `LiquidCrystal_I2C`
- SparkFun `MAX3010x Sensor Library`
- Adafruit `Thermal Printer Library`

选择 Mega 2560 是因为固件同时使用了 USB 串口、`Serial1` 和 `Serial2`。

## 快速运行（无硬件）

1. 使用 Processing 打开 `WSAA2_06/WSAA2_06.pde`。
2. 安装 Sound 和 oscP5 库。
3. 运行 sketch；程序会以全屏模式启动。
4. 按 `T` 开启键盘测试模式。
5. 使用方向键或 `W/A/S/D` 操作数据块，使用 `0`–`8` 模拟不同的 PMSD 输入。

程序会自动从项目根目录读取界面图像和 `0000.png`–`1111.png` 图形资源，从 `WSAA2_06/data/` 读取字体。

## 完整装置运行

1. 按下方接线表连接硬件，并确保所有模块共地。
2. 在 Arduino IDE 中打开并上传 `Arduino_Probiform_Printer_Bridge/Arduino_Probiform_Printer_Bridge.ino`。
3. 关闭 Arduino Serial Monitor，避免占用串口。
4. 启动 Processing sketch。
5. Processing 会优先寻找名称含 `usbmodem`、`usbserial` 或 `arduino` 的串口；找不到时会尝试列表中的第一个端口。
6. 触摸 MAX30102 心率传感器启动采集。系统也可在待机时通过超声波检测到观众并唤醒。

USB 串口波特率为 `115200`。系统连续 3 分钟未检测到参与者时会自动休眠。

## 硬件连接

| 模块 | Arduino Mega 2560 | 说明 |
| --- | --- | --- |
| 左超声波 TRIG | D2 | 距离输入 |
| 左超声波 ECHO | D3 | 距离输入；注意模块的逻辑电平要求 |
| 右超声波 TRIG | D4 | 距离输入 |
| 右超声波 ECHO | D5 | 距离输入；注意模块的逻辑电平要求 |
| 前左 MAX9814 | A0 | 机器反馈声音 |
| 前右 MAX9814 | A1 | 机器反馈声音 |
| 后左 KY-038 | A2 | 人声确认 |
| 后右 KY-038 | A3 | 人声确认 |
| LD2410 电源继电器 | D22 | 默认高电平开启；按继电器类型调整固件常量 |
| 数据 LCD | SDA 20 / SCL 21 | I2C 地址 `0x27`，20 × 4 |
| 打印 LCD | SDA 20 / SCL 21 | I2C 地址 `0x26`，20 × 4 |
| MAX30102 | SDA 20 / SCL 21 | I2C 心率/触摸启动传感器 |
| 热敏打印机 TTL | Serial1，TX1 D18 | `9600` baud |
| LD2410 | Serial2，RX2 D17 / TX2 D16 | `256000` baud |
| Processing 主机 | USB `Serial` | `115200` baud |

> 热敏打印机通常需要独立的大电流电源。不要直接使用 Arduino 的 5V 引脚为打印机供电，并务必将打印机电源地与 Arduino GND 共地。连接前请以具体模块的数据手册为准。

两个 LCD 必须使用不同的 I2C 地址。若实际地址不同，请修改固件中的 `DATA_LCD_ADDRESS` 和 `PRINT_LCD_ADDRESS`。

## 操作按键

### 常用控制

| 按键 | 功能 |
| --- | --- |
| `A` / `←` | 左移 |
| `D` / `→` | 右移 |
| `W` / `↑` | 旋转 |
| `S` / `↓` | 加速下落 |
| `Space` | 注入一次冲突 / 误读 |
| `C` | 清空沉积数据 |
| `M` | 开关机器声音 |
| `B` | 重新校准人声基线 |
| `U` | 连接 / 断开 Arduino 串口 |
| `V` | 向 Arduino 发送停止系统命令 |
| `P` | 手动打印当前液化图像（硬件模式） |
| `I` | 打印当前传感器状态（硬件模式） |
| `T` | 开关键盘测试模式 |

### 键盘测试模式

| 按键 | 功能 |
| --- | --- |
| `0`–`8` | 模拟不同 PMSD 状态 |
| `P` | 切换 Presence |
| `O` | 切换 Distance |
| `[` / `]` | 减少 / 增加模拟距离 |
| `Q` / `E` | 降低 / 提高模拟人声输入 |
| `Z` / `X` | 降低 / 提高模拟机器声输入 |

## PMSD 数据

系统把四类观测组合成一个 4-bit 状态：

- **P — Presence**：观众是否存在
- **M — Motion**：是否检测到移动
- **S — Sound**：是否检测到人声
- **D — Distance**：是否处于有效互动距离

这些数据影响图形类型、空间位置、可信度、固化程度和误读概率。装置不会把传感器读数视为绝对事实，而是将它们作为持续变化的推断依据。

## OSC / Max/MSP

Processing 在本机端口 `12000` 创建 OSC 实例，并以约 20 Hz 的频率向 `127.0.0.1:7400` 发送：

| OSC 地址 | 类型 | 内容 |
| --- | --- | --- |
| `/distanceL` | float | 左侧平滑距离 |
| `/distanceR` | float | 右侧平滑距离 |
| `/voice` | float | 人声强度 |
| `/confidence` | float | 当前数据可信度 |
| `/misread` | float | 当前误读 / 冲突量 |
| `/rotation` | int | 当前图形旋转状态 |
| `/drop` | int | 数据落下事件，值为 `1` |

未运行 Max/MSP 时，Processing 的视觉与内部声音系统仍可独立运行。

## 热敏打印

Processing 将当前液化场转换为 `192 × 128` 的 1-bit 位图，通过 USB 串口逐行发送给 Arduino。Arduino 再通过 `Serial1` 驱动打印机。

- 自动打印间隔：每 15 个沉积数据块
- 手动打印当前图像：`P`
- 打印状态票据：`I`
- 固件支持的串口命令：`PRINT_BITMAP`、`PRINT_TEST`、`PRINT_STATUS`、`STOP_SYSTEM`

打印期间常规传感器采集会暂时暂停，打印完成后自动恢复。

## 项目结构

```text
.
├── Arduino_Probiform_Printer_Bridge/
│   └── Arduino_Probiform_Printer_Bridge.ino
├── WSAA2_06/
│   ├── WSAA2_06.pde                 # Processing 入口与主循环
│   ├── Sensors.pde                  # 串口、传感器映射和参与状态
│   ├── GameInputData.pde            # 输入、PMSD 和下落数据
│   ├── SedimentSystem.pde           # 沉积、衰减和重力
│   ├── MemoryBoundary.pde           # 轨迹、冲突和感知边界
│   ├── LiquefactionField.pde        # 液化场视觉
│   ├── BlockDrawing.pde             # 数据块绘制
│   ├── InterfaceView.pde            # 界面与 HUD
│   ├── MachineSound.pde             # 实时声音合成
│   ├── OscBridge.pde                # OSC 输出
│   ├── ThermalPrintBridge.pde       # 位图生成与打印通信
│   └── data/                         # 字体资源
├── 0000.png … 1111.png              # 4-bit 图形资源
└── 其他 PNG / SVG                    # 界面视觉资源
```

## 常见问题

**Processing 提示找不到串口**  
确认 Arduino 已连接、Serial Monitor 已关闭，然后按 `U` 重连。若电脑连接了多个串口设备，可在 `Sensors.pde` 的 `initArduinoSerial()` 中明确指定端口。

**Processing 编译时提示找不到类**  
确认已安装 Sound 和 oscP5；Arduino 端则检查三个外部库是否已安装。

**LCD 没有显示**  
使用 I2C 扫描程序确认地址，并检查两个屏幕没有使用同一地址。

**打印机乱码、复位或打印过浅**  
检查独立供电、共地和 `9600` 波特率。打印浓度与加热参数可分别在 `ThermalPrintBridge.pde` 和 Arduino 固件中调整。

**没有硬件但想调试视觉**  
按 `T` 进入键盘测试模式，再用 `0`–`8`、`[`、`]`、`Q/E` 和 `Z/X` 模拟输入。

## 说明

本项目仍处于装置开发阶段。正式展出前，请根据现场环境重新校准声音阈值、超声波有效范围、LD2410 灵敏度以及热敏打印机加热参数。

## Generative AI Acknowledgement / 生成式人工智能使用声明

I acknowledge the use of [1] ChatGPT ([https://chat.openai.com/](https://chat.openai.com/)) to [2] assist with selected aspects of code development and debugging, provide suggestions on specific technical issues, and support language editing during the development of this assessment. I entered prompts including the following between **6 July and 2 August 2026**:

我确认在本评估项目的开发过程中使用了 [1] ChatGPT（[https://chat.openai.com/](https://chat.openai.com/)），用于 [2] 协助部分代码开发与调试、针对具体技术问题提供建议，并辅助文字润色。我于 **2026 年 7 月 6 日至 8 月 2 日** 输入的提示包括：

- [3] **Assist with developing and debugging selected functions in the Processing interface, particularly responsive layout behaviour, while retaining the existing Windows 95-inspired visual direction and interaction logic.**  
  [3] **请协助开发和调试 Processing 界面中的部分功能，尤其是响应式布局行为，同时保留现有的 Windows 95 视觉方向和交互逻辑。**

- [3] **Assist with connecting the Arduino Mega 2560 to the Processing program and debugging USB serial communication for ultrasonic, sound, heart-rate/touch, and LD2410 radar data, including port selection, baud-rate configuration, data formatting, and parsing.**  
  [3] **请协助将 Arduino Mega 2560 连接至 Processing 程序，并调试超声波、声音、心率/触摸及 LD2410 雷达数据的 USB 串口通信，包括端口选择、波特率设置、数据格式和解析。**

- [3] **Suggest an implementation approach for replacing the previous thermal-printing output with a locally generated QR-code archive, including automatic generation and manual display controls.**  
  [3] **请针对将原有热敏打印输出替换为本地生成的二维码归档提出实现建议，包括自动生成和手动显示控制。**

- [3] **Help improve the clarity and bilingual wording of selected sections of the project documentation without changing their technical meaning.**  
  [3] **请在不改变技术含义的前提下，协助改善项目文档中部分内容的清晰度和双语表述。**

[4] The outputs were treated as suggestions rather than final material. Relevant suggestions were evaluated, adapted, and tested by the author before use. The project's concept, research direction, interaction design, visual and sound decisions, hardware implementation, and final presentation were developed and determined by the author. The author accepts responsibility for the accuracy, integrity, and final outcome of the submitted work.

[4] 相关输出仅被视为建议，而非最终材料。作者在采用前对相关建议进行了评估、调整与测试。项目的创作概念、研究方向、交互设计、视觉与声音判断、硬件实施及最终呈现均由作者完成并决定。作者对所提交作品的准确性、完整性及最终成果承担责任。
