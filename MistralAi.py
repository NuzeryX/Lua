from openai import OpenAI

def create_chatbot():
    client = OpenAI(
        api_key="oELJnave2rOev19aZGyaDltZS1jGPcQL",
        base_url="https://api.mistral.ai/v1"
    )
    
    messages = []
    
    print("Mistral AI Chatbot (Ctrl+C to exit)")
    print("------------------------------------")
    
    while True:
        try:
            user_input = input("\nYou: ").strip()
            if not user_input:
                continue
                
            messages.append({"role": "user", "content": user_input})
            
            chat_response = client.chat.completions.create(
                model="mistral-medium",
                messages=messages
            )
            
            assistant_content = chat_response.choices[0].message.content
            print("\nAI:", assistant_content)
            
            messages.append({"role": "assistant", "content": assistant_content})
            
        except KeyboardInterrupt:
            print("\n\nGoodbye!")
            break
        except Exception as e:
            print(f"\nError occurred: {str(e)}")
            break

if __name__ == "__main__":
    create_chatbot()