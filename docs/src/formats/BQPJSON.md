# BQPJSON

## Format

```@docs
QUBOTools.BQPJSON
```

## Example

```
{
    "id": 2,
    "version": "1.0.0",
    "description": "Simple QUBO Problem",
    "scale": 2.7,
    "offset": 1.93,
    "linear_terms": [
        {
            "id": 1,
            "coeff": 0.0
        },
        {
            "id": 3,
            "coeff": 0.4
        },
        {
            "id": 5,
            "coeff": -4.4
        }
    ],
    "quadratic_terms": [
        {
            "id_head": 1,
            "coeff": -0.8,
            "id_tail": 3
        },
        {
            "id_head": 1,
            "coeff": 6.0,
            "id_tail": 5
        }
    ],
    "variable_domain": "boolean",
    "variable_ids": [
        1,
        3,
        5
    ],
    "metadata": {},
    "solutions": [
        {
            "evaluation": 6.291,
            "id": 0,
            "assignment": [
                {
                    "id": 1,
                    "value": 0
                },
                {
                    "id": 3,
                    "value": 1
                },
                {
                    "id": 5,
                    "value": 0
                }
            ],
            "description": "first solution"
        },
        {
            "evaluation": 9.531,
            "id": 1,
            "assignment": [
                {
                    "id": 1,
                    "value": 1
                },
                {
                    "id": 3,
                    "value": 0
                },
                {
                    "id": 5,
                    "value": 1
                }
            ],
            "description": "second solution"
        }
    ]
}
```