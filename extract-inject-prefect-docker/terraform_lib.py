import json
import python_terraform as terraform

# создаем объект Terraform
tf = terraform.Terraform(working_dir='../terraform')

# вызываем команду "output" в Terraform и сохраняем результат в переменную
output = tf.output()
print(output)
# парсим JSON-строку в словарь Python
#output_dict = json.loads(output)
#print(output_dict)
# # получаем значение конкретного output по имени
# output_value = output_dict['output_name']['value']

# print(output_value)