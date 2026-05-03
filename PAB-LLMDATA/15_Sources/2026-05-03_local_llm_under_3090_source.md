---
title: "Reddit r/LocalLLaMA — Can you run actually useful LLMs on anything less than 3090? (원문)"
description: "RTX 3060 12GB로 자체 호스팅 가능한 LLM이 있는지 묻는 Reddit 글 원문 + 톱 댓글 트리 immutable 보존."
created: 2026-05-03 06:45
updated: 2026-05-03 06:45
type: "[[SOURCE]]"
index: "[[AI]]"
topics: ["[[LOCAL_LLM_HOSTING]]"]
tags: [source, llm, local-hosting, gpu, vram, reddit]
keywords: ["RTX 3060", "RTX 3090", "12GB VRAM", "MoE", "Qwen3.5", "Gemma 4", "GLM 4.7", "self-hosting"]
sources: ["https://www.reddit.com/r/LocalLLaMA/comments/1sl3ztq/can_you_run_actually_useful_llms_on_anything_less/"]
aliases: ["LocalLLaMA 3090 토론 원문", "12GB VRAM LLM 호스팅 토론"]
---

> ⚠️ 변경 금지 — 원본 immutable 보존 (`/pab:wiki` 자동 생성, Karpathy raw sources 계층)

# Can you run actually useful LLMs on anything less than 3090?

**Subreddit**: r/LocalLLaMA
**Author**: u/Relevant-Pie475
**Posted**: 2026-05-03 (UTC 1776160100)
**Score**: 5  |  **Comments**: 34
**URL**: https://www.reddit.com/r/LocalLLaMA/comments/1sl3ztq/can_you_run_actually_useful_llms_on_anything_less/

## Original Post

I started my LLM self-hosting journey with a 1660 Ti (Bad Choice, I know)

I wanted to get started a bit quickly, and this was the first GPU that I could buy without breaking much bank

However, I soon realized that this is extremely under-powered. So I started looking for a GPU with more VRAM. I came across 3060, which seem to me a good balance between raw GPU performance & cost

Afterwards, I reached out to a colleague who is also very active in self-hosting LLMs. I told him that I got a 3060, and his first response is that it sucks. He is running his setup on a 3090, and is planning to get another one

Honestly, I don't consider myself a AI power-user. I'm mostly self-hosting it for my family, to provide them a more ethical choice to use AI as compared to commercial offerings, and also due to data & privacy concerns

But my main question is that for you LLM experts, is it possible to host a relatively useful LLM on a GPU with 12 GB VRAM? I did some research before buying, and it seemed like a good balance for the cost-power ratio. But honestly hearing regarding the performance from the colleague, it affected my confidence in the setup & started questioning regarding if I'll be able to self-host LLMs without dropping 1000$ for the hardware

I understand it doesn't matter much, but I plugged the GPU into an HP workstation with Intel Xeon & 32 GBs of DDR3 RAM. I didn't get a chance to run the benchmarks, but overall I thought the performance was good enough for the personal use case

So I wanted you all to share your experiences with hosting LLMs with anything under 3090!

## Comments

### u/Momsbestboy (score 8)

3060 is fine. You just need more time for waiting, until it has run a task. I am using Qwen3.5 35B A3B Q6, with offload to RAM, and while it really isn't fast, it gets the job done - for me: bash scripts, python scripts etc. I need them locally, and I am too lazy /too cautious to post them on ChatGPT, or filter privacy relevant data before uploading to GPT.

Why no 3090?

I decided against it, because I don't want to spend 900 Euro on a used card I have to grab from Ebay, with no warranty and a good chance it spent the last 6 years running at 100% in a mining rig.

#### └ u/slimdizzy (score 2)

FWIW GPU mining is effectively dead and when the 3000 series dropped Nvidia had them rate limited with only the founders edition getting BIOS hacks, if I recall directly as I used to mine ETH. Used 3090s should be fine less some crazy overclocking gamer.

##### └─ u/Makers7886 (score 3)

3090 mining died about a year after it's release (I bought 12 during that time for mining) with some stragglers holding on for another year or so. I upgraded all thermal pads (they are bad quality almost across the board) and they have all been flawless minus having to replace 2-3 fans total. The good thing about mining "wear" is that you typically downclock the core but OC the vram and the temps are consistent and sustained - less thermal cycling. All 12 of my gpus are running strong to this day without any bad signs and now living a happy retirement life serving LLM's.

tldr: The 3090s are workhorses - but they need thermal pad upgrades.

###### └── u/slimdizzy (score 2)

Yep just as I remember then. Glad your cards are doing other work now!

#### └ u/chopticks (score 1)

What approx tokens/sec are you getting? I'm personally ok with around 10 so curious to see what you're getting

##### └─ u/Momsbestboy (score 3) — benchmark

```
llama-bench -m ./Qwen3.5-35B-A3B-UD-Q6_K_XL.gguf -ncmoe 28 -ngl 99 -b 512 -t 8 -fa 1
ggml_cuda_init: found 1 CUDA devices (Total VRAM: 12037 MiB):
Device 0: NVIDIA GeForce RTX 3060, compute capability 8.6, VMM: yes, VRAM: 12037 MiB
| model                          |       size |     params | backend | ngl | n_batch | fa |  test | t/s              |
| ------------------------------ | ---------: | ---------: | ------- | --: | ------: | -: | ----: | ---------------: |
| qwen35moe 35B.A3B Q6_K         |  29.86 GiB |    34.66 B | CUDA    |  99 |     512 |  1 | pp512 |   343.22 ± 3.24  |
| qwen35moe 35B.A3B Q6_K         |  29.86 GiB |    34.66 B | CUDA    |  99 |     512 |  1 | tg128 |    35.30 ± 0.21  |

build: d3936498a (8370)
```

And my llm-models.ini

```
[Qwen3.5_Q6_noReason-35B-A3B-Q6_K_XL no reason]
model = /home/x/llm/gguf/Qwen3.5-35B-A3B-UD-Q6_K_XL.gguf
c = 32768
ncmoe = 28
n-gpu-layers = 99
b = 512
fa = 1
temp = 0.6
top-p = 0.95
min-p = 0.0
ctk = bf16
ctv = bf16
repeat-penalty = 1.0
presence-penalty = 0.0
```

###### └── u/chopticks (score 1)

Thanks!

#### └ u/Relevant-Pie475 (OP, score 1)

Thats what I was concerned about. The price to performance ration does not make sense for my use case, especially because I'm just starting out on my LLM hosting journey, and don't want to spend a good 1000 bucks on a 3090

But thanks for providing the context. I think I might need to fine tune some parameters and I should be able to run some solid models at an acceptable performance

Right now, I have ran Qwen 3.5 9B with acceptable performance

### u/NekoRobbie (score 5)

Depends on what you mean by useful.

The system RAM might actually be more helpful than you think, because it means that you can afford to use some larger MoEs. MoEs can let systems punch well above their weight, and they actually make good use of system RAM because you can put a surprising amount of the MoE into RAM while maintaining very good performance.

I know that I can run Gemma 4 26B A4B at IQ4_XS with 64k context (at q8 kv cache) on my RX 9060 XT 16GB very comfortably while only offloading 8 or so MoE layers to RAM (using SWA, since Gemma 4 was kinda built around it). A MoE won't be quite as a good as a dense model of their total parameter count, but they're certainly far better than their active parameter count alone. I think you could probably get at *least* 32k context with the MoE yourself, and if you're willing to offload more of the layers to RAM than I currently am then you could probably get up to 64k+ yourself. Overall, from what I've heard, people are having pretty darn good success with using the model for (some) local AI-assisted coding.

If wanting to avoid MoE / wanting to keep things fully in VRAM, there's always Qwen 3.5 9B or Gemma 4 E4B (E4B is actually an 8B model, but it apparently is as performant as 4B. Hence the "E" for "Effectively"). Definitely adjust your expectations to their size, though.

#### └ u/Relevant-Pie475 (OP, score 1)

Yes thank you for the breakdown. I need to dive a bit more into the different type of Models, but I do have the understanding that MoE models are okay for day to day use, but for some specific application, such as coding, you will need a specific model to get stronger results (more accurate, less hallucinations) etc.

Right now, I have tested the following models somewhat thoroughly

- Qwen 3.5B - 9B
- Ministral-3 - 8B
- Gemma3 - (8B & 12B)

Overall I would say compared to the online models, the responses seem weaker (more hallucinations, less details) but thats expected, since the hardware is significantly weaker than cloud offerings

But the performance was okay for the most part

### u/Long_comment_san (score 4)

I use 12gb 4070. Literally 2/3 of the moe models work fine provided you have the ram. GLM 4.7 flash, Qwen 35ba3b and new Gemma 4 26b seem like your only choice. I recomend GLM and Gemma

#### └ u/Relevant-Pie475 (OP, score 1)

Hi Thanks for sharing! I have heard of Gemma, but not GLM. I'll have a look!

##### └─ u/Long_comment_san (score 1)

GLM 4.7 flash is really not bad at all. Take a look at Melinoe. I hype them, they are absolutely amazing models. Whoever made them doesn't get the recognition he deserved. I absolutely loved Melinoe 80 (Next) and then flash came out which keeps me very happy.

Gemma 4, however, should be a tier above Melinoe in brainpower. Basically Melinoe is a lot more fun to talk to, but Gemma is a better workhorse.

### u/Skyline34rGt (score 3)

Rtx3060 gives you MoE models like: Qwen3.5 35b-a3b (q4_k_m) and Gemma4 26-a4b (q4_k_m) with offload MoE layers to Cpu.

You can have ~40tok/s for Qwen and ~30tok/s for Gemma4 (of more with new updated quants maybe?)

What can Rtx3090 better have? Dense models will run:

Qwen3.5 27b and Gemma 31b - they are a little better than MoE but they are slower even at 3090.

So a lot cheaper Gpu gives you very fast, almost as good models as Rtx3090.

Many people have Rtx3090 and still prefer MoE model cause of speed.

#### └ u/Relevant-Pie475 (OP, score 1)

Alright thanks for the input!

### u/cviperr33 (score 2)

Well im running local models on 3090 and this is my conclusion;

You cant really run the 26-35 models bellow 16gb vram, just the weights are 12GB minimum at IQ2 quant, the most aggresive one that makes the model lobotomized. You need space for contex to make it a usefull tool. Offloading to RAM makes it soo slow that you are never gonna use it daily, it will always be way faster just to ask claude or chat gtp your question, unless you are using the new macs with unified memory but those are expensive.

Your only options with 12gb vram gpus is the small 9b models, which works but they are just not as capable, i dont know what kind of use case you can get them from them.

What uses people get from local llm: On 24gb cards you can load a capable model for your coding agents, there are so many ways to improve it and tune it, you can narrow its abilities to only coding, load a dense 32b model and load a speculative decoding small model to improve the TK/s by almost double on coding, you can get claude level of code quality but your model will be limited to only coding and you have to change your settings depending on the use case (inconvenience you pay for llocal llm) but i can itterate over my code unlimited times, since im not paying apis or subs

Other use cases are like the uncensored models, for fictional writing or whatever comes to your mind, those models dont refuse your prompt and you can only get this locally.

For search engine tool, the 9b models and bellow could probably handle it? No idea i have not tested it myself, but to be able to use the search engine tool, it needs to be smart model and the contex needs to be large because each page visited increases the contex by 10k.

Local llm models are getting optimized month by month, what was possible to run on 24gb card a year ago, can be run nowdays on like 2-5gb for the same quality, so we are always advancing, people are using crazy tech's like distilling and mixture of experts, who knows what else they will invent in a year, TurboQuant by google looks really promising, it can do like 6x compression without loosing quality (we will see), in a year maybe you can host a claude opus intelligence on a 12gb card with full contex.

#### └ u/Relevant-Pie475 (OP, score 1)

Thanks for sharing your experience. I have tried online searching, but the performance is just too damn slow, with the responses being even worse. So I had to accept that for the models, they will stick to their knowledge cut-off, without much support for online / web searching

##### └─ u/cviperr33 (score 1)

You can def get a usecase from local models, i mean just researching and trying is just fun, people love tinkering and exploring ideas.
Probaly most of the people that have these expensive cards, came from a gaming background, for me it was no brainer spending 550 euros on 3090 a year ago, because i knew in the future i would be interested in playing around with LLMs and i also game a lot, like most of the year that has passed 95% of the time it was spend with gaming lol i just recently (2 weeks ago) started doing really deep dives into local models, gemma 4 was lke mind blowing how good that model is.

If you dont play games i dont see a reason for you to look for and buy such expensive hardware for a hobby, your options for cards are like limited, you want to have at minimum 16gb, but those are rly expensive, and they are designed for gaming, not for hosting AI models.

There is like these mini pc's that are just for hosting lm's with unified memory, if you can get a good deal on a used one, this would probably be the best bang for your buck.

###### └── u/Relevant-Pie475 (OP, score 1)

Yes thanks for sharing the background. I do play games, but I have a seperate PC for that, which I built myself

That is a really heavy build, so I don't really want it to be running 24/7 (due to energy cost)

But I have this workstation running, for which I bought a 3060 & wanted it to share with my family for AI use. Since its a relatively less energy intensive, I'm okay with it running 24/7

But yea thanks for the background!

### u/Relevant-Pie475 (OP, score 2)

Sorry guys, I posted this at the beginning of my work day. Just got some time to respond

### u/sleepynate (score 2)

You don't really need a gigantic model for a lot of useful things. I use 3B-4B models for most of my agent bots, specifically I was running Nemotron 3 Nano although I've been playing with Gemma4:E4B this week. The power and value that they have really comes from the RAG and MCP abilities, so with a smaller model I can crank up the context window to 64k to give plenty of room for the prompt and tools and still fit comfortably on a 3060. A model doesn't really need to be super smart of do something like check ebay listings or give me an update on the news headlines. I had Google's AI mode write what little code was needed for them.

### u/Comfortable_Ad_8117 (score 1)

I have a dedicated box with a pair of 3060's and it works great.. speed is perfect for what I do with it. I run all sorts of good models - 24b ~ 30b without issue.

### u/ambient_temp_xeno (score 1)

3060 12gbs are fine as long as you have two.

#### └ u/Relevant-Pie475 (OP, score 1)

Yea the thing is the workstation that I'm using, does not have space for 2 GPUs. The case only can hold one

### u/rosaccord (score 1)

I am happily running Qwen 3.5 27b q3 on 16GB VRAM - that's RTX 4080.

Context size 60k suits me well and performance 40t/s is good for my tasks,

(image: https://preview.redd.it/qyl0i0xw15vg1.png)

see here quality tests details: https://www.glukhov.org/ai-devtools/opencode/llms-comparison/

and here speed test: https://www.glukhov.org/llm-performance/benchmarks/best-llm-on-16gb-vram-gpu/

### u/NotaDevAI (score 1)

MoE normally works on many low GPU local setup along with RAM due to its architecture. Or you can quantize some dense models.

### u/DeltaSqueezer (score 1)

it depends on what you are using it for. i think a good baseline would be qwen3.5 9B for general light tasks.

### u/PermanentLiminality (score 1)

I'm running 2x P40 or less than half the cost of one 3090. At best one third the speed, but double the VRAM.

### u/Boricua-vet (score 1)

100 bucks on a pair of P102-100 for a total of 20GB VRAM.

(image: https://preview.redd.it/olts2y4se7vg1.png)

More than enough for my needs. I don't see a need to spend crazy money when 100 bucks does this good for LLM only.

### u/ai_guy_nerd (score 1)

12GB is absolutely enough to run very useful models. The colleague is likely comparing it to the 24GB of a 3090, but that's a different league of use case. For a family setup, a 4-bit quant of Llama 3 8B or Mistral Nemo 12B will run fast and handle most daily tasks with ease.

The key is the quantization. Using GGUF or EXL2 formats allows these models to fit comfortably in 12GB while keeping most of their intelligence. You aren't dropping 000 for a 3090 unless you need to run 30B+ models or massive context windows.

If the goal is just a private, ethical alternative for the family, a 3060 is a fantastic entry point. For managing the agent logic and memory, something like OpenClaw can help turn a basic LLM into a useful tool. Don't let the 'power user' noise discourage you.

#### └ u/Relevant-Pie475 (OP, score 1)

The most motivating comment! Thanks so much for providing the comment! I'll make sure to continue on with my AI Journey with the system that I have! Hopefully I have some positive results to post once I'm done with the initial testing

### u/Status_Record_1839 (score 0)

3060 12GB works fine for personal use. Running Qwen2.5 7B or Mistral 7B at Q4 fits entirely in VRAM, ~30t/s. For bigger models you offload layers to RAM - slower but usable. The 3090 is only worth it if you specifically need 24GB in VRAM for larger models without offload.

#### └ u/Relevant-Pie475 (OP, score 1)

Yea thats the thing, I'm not sure even if I want that much VRAM, since the use case is a little unclear to me right now, since I'm still starting out on my journey. So spending that big a chunk of money on something regarding which I'm not sure will be required in the long term, does not seem logical to me

Thanks for sharing your experience!
