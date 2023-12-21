import json
import argparse

# コマンドライン引数を解析するための関数
def parse_args():
    parser = argparse.ArgumentParser(description="JSONLファイルを変換するスクリプト")
    parser.add_argument("--input_path", type=str, required=True, help="入力ファイルのパス")
    parser.add_argument("--output_path", type=str, required=True, help="出力ファイルのパス")
    return parser.parse_args()

# JSONオブジェクトを指定されたフォーマットに変換する関数
def convert_to_prompt_format(json_obj):
    input_exists = 'input' in json_obj and json_obj['input'] != ""

    output_exists = 'output' in json_obj

    if input_exists:
        prompt = PROMPT_DICT['prompt_input'].format(
            instruction=json_obj['instruction'],
            input=json_obj['input'],
            output=json_obj['output'] if output_exists else ""
        )
    else:
        prompt = PROMPT_DICT['prompt_no_input'].format(
            instruction=json_obj['instruction'],
            output=json_obj['output'] if output_exists else ""
        )

    return prompt

# Define the prompt templates
PROMPT_DICT = {
    "prompt_input": (
        "### 指示：以下に、あるタスクを説明する指示があり、それに付随する入力が更なる文脈を提供しています。リクエストを適切に完了するための回答を記述してください。\n\n ### 質問：\n{instruction}\n\n### 入力:\n{input}\n\n ### 回答：{output}"
    ),
    "prompt_no_input": (
        "### 指示：以下に、あるタスクを説明する指示があります。リクエストを適切に完了するための回答を記述してください。\n\n ### 質問：\n{instruction}\n\n ### 回答：{output}"
    ),
}

# コマンドライン引数を解析
args = parse_args()

# JSONLファイルを読み込む
json_list = []
with open(args.input_path, 'r', encoding='utf-8') as input_file:
    for line in input_file:
        record = json.loads(line)
        json_list.append(record)

# 変換したプロンプトをファイルに書き出す
with open(args.output_path, 'w', encoding='utf-8') as output_file:
    for line in json_list:
        converted_prompt = convert_to_prompt_format(line)
        converted_prompt_json = {"text": converted_prompt}
        output_file.write(json.dumps(converted_prompt_json, ensure_ascii=False) + '\n')

# 完了メッセージを表示
print("変換が完了しました。出力ファイル:", args.output_path)