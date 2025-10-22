import os
import sys
import tkinter as tk
from tkinter import filedialog, messagebox, simpledialog
import logging
from datetime import datetime
import traceback
import time

if getattr(sys, 'frozen', False):
    script_dir = os.path.dirname(sys.executable)
else:
    script_dir = os.path.dirname(os.path.abspath(__file__))

log_dir = os.path.join(script_dir, "LOG")
os.makedirs(log_dir, exist_ok=True)

log_file = os.path.join(log_dir, datetime.now().strftime("%Y-%m-%d_%H-%M-%S.log"))

logging.basicConfig(
    filename=log_file,
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    encoding="utf-8"
)

def run_app(root):
    try:
        logging.info("=== Запуск скрипта ===")

        input_files = filedialog.askopenfilenames(
            parent=root,
            title="Выберите один или несколько файлов с логами",
            filetypes=[("All files", "*.*"), ("Text files", "*.txt"), ("Log files", "*.log")]
        )

        if not input_files:
            messagebox.showinfo("Отмена", "Файлы не выбраны.", parent=root)
            logging.info("Файлы не выбраны, работа завершена.")
            root.quit()
            return

        keywords_input = simpledialog.askstring(
            "Ключевые слова",
            "Введите ключевые слова через запятую или точку с запятой:",
            parent=root
        )

        if not keywords_input:
            messagebox.showinfo("Отмена", "Ключевые слова не заданы.", parent=root)
            logging.info("Ключевые слова не заданы, работа завершена.")
            root.quit()
            return

        separators = [",", ";"]
        for sep in separators:
            if sep in keywords_input:
                keywords = [w.strip() for w in keywords_input.split(sep) if w.strip()]
                break
        else:
            keywords = [keywords_input.strip()]

        total_count = 0
        processed_files = []

        start_time = time.time()

        for input_file in input_files:
            input_filename = os.path.basename(input_file)
            name, ext = os.path.splitext(input_filename)
            output_file = os.path.join(script_dir, f"{name}{ext}_filtered.txt")

            count = 0
            lines_to_write = []

            with open(input_file, "r", encoding="utf-8", errors="ignore") as infile:
                for line in infile:
                    if any(word in line for word in keywords):
                        lines_to_write.append(line)
                        count += 1

            if count > 0:
                with open(output_file, "w", encoding="utf-8") as outfile:
                    outfile.writelines(lines_to_write)

                processed_files.append((input_file, output_file, count))
                logging.info(f"[ФАЙЛ] {input_file}")
                logging.info(f"  Выходной файл: {output_file}")
                logging.info(f"  Найдено строк: {count}")
                total_count += count
            else:
                logging.info(f"[ФАЙЛ] {input_file} — совпадений не найдено, выходной файл не создан.")

        elapsed = round(time.time() - start_time, 2)

        logging.info(f"Ключевые слова: {', '.join(keywords)}")
        logging.info(f"Всего найдено строк по всем файлам: {total_count}")
        logging.info(f"Время выполнения: {elapsed} сек.")
        logging.info("=== Завершение работы скрипта ===")

        if processed_files:
            result_msg = f"Фильтрация завершена!\n\nКлючевые слова: {', '.join(keywords)}\n\n"
            for inp, outp, cnt in processed_files:
                result_msg += f"{os.path.basename(inp)} → {os.path.basename(outp)} (строк: {cnt})\n"
            result_msg += f"\nВсего найдено строк: {total_count}\n"
            result_msg += f"\nЛог сохранён в:\n{log_file}\n"
            result_msg += f"Время выполнения: {elapsed} сек."
            messagebox.showinfo("Готово", result_msg, parent=root)
        else:
            messagebox.showinfo("Результат", "Совпадений не найдено ни в одном из файлов.", parent=root)

    except Exception as e:
        err_msg = traceback.format_exc()
        logging.error(f"Ошибка: {err_msg}")
        messagebox.showerror("Ошибка", f"Во время работы возникла ошибка:\n{e}", parent=root)

    finally:
        root.quit()

def main():
    root = tk.Tk()
    root.withdraw()
    root.after(100, lambda: run_app(root))
    root.mainloop()

if __name__ == "__main__":
    main()