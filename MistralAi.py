def create_chatbot():
    from openai import OpenAI
    c = OpenAI(api_key="oELJnave2rOev19aZGyaDltZS1jGPcQL", base_url="https://api.mistral.ai/v1")
    m = []
    print("Mistral AI Chatbot\n-----------------")
    [[m.append({"role":"user","content":i}), 
      print("\nAI:", ((r:=c.chat.completions.create(model="mistral-medium",messages=m)).choices[0].message.content)),
      m.append({"role":"assistant","content":r.choices[0].message.content})]
      for i in iter(lambda:input("\nYou: ").strip(),KeyboardInterrupt)]

if __name__ == "__main__":
    create_chatbot()